// lib/features/translate_call/application/call_controller.dart

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../../../core/constants.dart';
import '../data/translate_call_repository.dart';
import '../domain/call_language.dart';
import '../domain/call_session.dart';
import 'providers.dart';

// ── CallPhase ─────────────────────────────────────────────────────────────────

enum CallPhase {
  idle,
  ringingOutgoing,
  ringingIncoming,
  connecting,
  active,
  ended,
}

// ── CallState ─────────────────────────────────────────────────────────────────

class CallState {
  const CallState({
    this.phase             = CallPhase.idle,
    this.sessionId,
    this.session,
    this.myLanguage,
    this.partnerLanguage,
    this.myTranscript      = '',
    this.partnerTranscript = '',
    this.isMuted           = false,
    this.callDuration      = Duration.zero,
    this.error,
  });

  final CallPhase phase;
  final String? sessionId;
  final CallSession? session;
  final CallLanguage? myLanguage;
  final CallLanguage? partnerLanguage;
  final String myTranscript;
  final String partnerTranscript;
  final bool isMuted;
  final Duration callDuration;
  final String? error;

  bool get isActive  => phase == CallPhase.active;
  bool get isRinging => phase == CallPhase.ringingOutgoing ||
                        phase == CallPhase.ringingIncoming;
  bool get isIdle    => phase == CallPhase.idle;

  CallState copyWith({
    CallPhase? phase,
    String? sessionId,
    CallSession? session,
    CallLanguage? myLanguage,
    CallLanguage? partnerLanguage,
    String? myTranscript,
    String? partnerTranscript,
    bool? isMuted,
    Duration? callDuration,
    String? error,
  }) =>
      CallState(
        phase:             phase            ?? this.phase,
        sessionId:         sessionId        ?? this.sessionId,
        session:           session          ?? this.session,
        myLanguage:        myLanguage       ?? this.myLanguage,
        partnerLanguage:   partnerLanguage  ?? this.partnerLanguage,
        myTranscript:      myTranscript     ?? this.myTranscript,
        partnerTranscript: partnerTranscript ?? this.partnerTranscript,
        isMuted:           isMuted          ?? this.isMuted,
        callDuration:      callDuration     ?? this.callDuration,
        error:             error,
      );
}

// ── Controller ────────────────────────────────────────────────────────────────

class CallController extends AsyncNotifier<CallState> {
  final _recorder   = AudioRecorder();
  final _player     = AudioPlayer();
  final _audioQueue = StreamController<Uint8List>.broadcast();

  StreamSubscription<WsEvent>?     _wsEventSub;
  StreamSubscription<List<int>>?   _audioStreamSub;
  StreamSubscription<CallSession>? _firestoreSub;

  Timer? _callTimer;
  Timer? _ringingTimer;
  Timer? _connectingTimeoutTimer;

  DateTime? _callStartTime;

  @override
  Future<CallState> build() async {
    ref.onDispose(_cleanup);
    return const CallState();
  }

  // ── Initiate call (caller side) ───────────────────────────────────────────

  Future<void> initiateCall({
    required String receiverUid,
    required String receiverName,
    required CallLanguage myLanguage,
    required CallLanguage partnerLanguage,
  }) async {
    state = const AsyncLoading();

    try {
      final micOk = await _requestMic();
      if (!micOk) {
        state = AsyncData(const CallState(
          error: 'Microphone permission is required to make calls.',
        ));
        return;
      }

      final repo = ref.read(translateCallRepositoryProvider);
      final user = ref.read(firebaseAuthProvider).currentUser!;

      // Fetch receiver FCM token from Firestore
      final receiverFcmToken = await repo.fetchReceiverFcmToken(receiverUid);
      if (receiverFcmToken == null) {
        state = AsyncData(const CallState(
          error: 'Could not reach this contact. They may be offline.',
        ));
        return;
      }

      final sessionId = await repo.createBackendSession();

      final session = CallSession(
        sessionId:        sessionId,
        callerUid:        user.uid,
        receiverUid:      receiverUid,
        callerName:       user.displayName ?? 'Unknown',
        receiverName:     receiverName,
        callerLang:       myLanguage.sourceLang,
        receiverLang:     partnerLanguage.sourceLang,
        status:           CallStatus.ringing,
        createdAt:        DateTime.now(),
        receiverFcmToken: receiverFcmToken,
      );

      await repo.createCallDoc(session);

      state = AsyncData(CallState(
        phase:           CallPhase.ringingOutgoing,
        sessionId:       sessionId,
        session:         session,
        myLanguage:      myLanguage,
        partnerLanguage: partnerLanguage,
      ));

      _watchForAnswer(sessionId, myLanguage, partnerLanguage);

      _ringingTimer = Timer(AppConstants.ringingTimeout, () {
        _handleMissed(sessionId);
      });
    } catch (e, st) {
      debugPrint('[CallController] initiateCall error: $e\n$st');
      state = AsyncData(CallState(error: _friendlyError(e)));
    }
  }

  // ── Accept call (receiver side) ───────────────────────────────────────────
  //
  // ORDER MATTERS:
  //   1. Connect WS first → receiver is ready on the backend
  //   2. Then set Firestore status=active → caller sees it and connects
  //
  // If we set Firestore first, the caller may connect to the backend before
  // the receiver, and the backend may never fire call_started because
  // user-index-0 (receiver) arrived after user-index-1 (caller).

  Future<void> acceptCall({
    required CallSession incomingSession,
    required CallLanguage myLanguage,
  }) async {
    state = const AsyncLoading();

    try {
      final micOk = await _requestMic();
      if (!micOk) {
        state = AsyncData(const CallState(error: 'Microphone permission required.'));
        return;
      }

      final repo          = ref.read(translateCallRepositoryProvider);
      final partnerLang   = CallLanguage.fromSourceLang(incomingSession.callerLang);
      final notifications = ref.read(notificationServiceProvider);

      await notifications.dismissIncomingCall(incomingSession.sessionId);

      state = AsyncData(CallState(
        phase:           CallPhase.connecting,
        sessionId:       incomingSession.sessionId,
        session:         incomingSession,
        myLanguage:      myLanguage,
        partnerLanguage: partnerLang,
      ));

      // Step 1: connect WS (receiver joins the backend session first)
      await _connectAndStartAudio(
        sessionId:       incomingSession.sessionId,
        myLanguage:      myLanguage,
        partnerLanguage: partnerLang,
      );

      // Step 2: signal Firestore → caller connects WS
      await repo.updateCallStatus(incomingSession.sessionId, CallStatus.active);

      // Guard: if call_started never arrives within 30s, abort
      _startConnectingTimeout(incomingSession.sessionId);
    } catch (e, st) {
      debugPrint('[CallController] acceptCall error: $e\n$st');
      await _cleanup();
      state = AsyncData(CallState(error: _friendlyError(e)));
    }
  }

  // ── Decline call (receiver side) ──────────────────────────────────────────

  Future<void> declineCall(String sessionId) async {
    final repo          = ref.read(translateCallRepositoryProvider);
    final notifications = ref.read(notificationServiceProvider);

    await notifications.dismissIncomingCall(sessionId);

    try {
      await repo.updateCallStatus(sessionId, CallStatus.declined);
    } catch (e) {
      debugPrint('[CallController] declineCall error: $e');
    }

    state = const AsyncData(CallState());
  }

  // ── Hang up (either side) ─────────────────────────────────────────────────

  Future<void> hangUp() async {
    final current   = state.valueOrNull;
    final sessionId = current?.sessionId;
    final startTime = _callStartTime;
    final session   = current?.session;

    _ringingTimer?.cancel();
    _connectingTimeoutTimer?.cancel();
    await _cleanup();

    if (sessionId != null) {
      final repo     = ref.read(translateCallRepositoryProvider);
      final duration = startTime != null
          ? DateTime.now().difference(startTime).inSeconds
          : null;

      try {
        await repo.updateCallStatus(
          sessionId,
          CallStatus.ended,
          endedAt:         DateTime.now(),
          durationSeconds: duration,
        );

        if (session != null && duration != null) {
          final data = {
            'status':          CallStatus.ended.name,
            'endedAt':         DateTime.now(),
            'durationSeconds': duration,
          };
          await repo.updateHistoryEntry(session.callerUid,   sessionId, data);
          await repo.updateHistoryEntry(session.receiverUid, sessionId, data);
        }

        await repo.endBackendSession(sessionId);
      } catch (e) {
        debugPrint('[CallController] hangUp cleanup error: $e');
      }
    }

    state = const AsyncData(CallState(phase: CallPhase.ended));
    await Future.delayed(const Duration(seconds: 2));
    if (state.valueOrNull?.phase == CallPhase.ended) {
      state = const AsyncData(CallState());
    }
  }

  // ── Toggle mute ───────────────────────────────────────────────────────────

  void toggleMute() {
    final current = state.valueOrNull;
    if (current == null || !current.isActive) return;

    final muted = !current.isMuted;
    if (muted) {
      _recorder.pause();
    } else {
      _recorder.resume();
    }
    state = AsyncData(current.copyWith(isMuted: muted));
  }

  // ── Internal: watch Firestore for receiver response (caller side) ─────────

  void _watchForAnswer(
    String sessionId,
    CallLanguage myLanguage,
    CallLanguage partnerLanguage,
  ) {
    final repo = ref.read(translateCallRepositoryProvider);

    _firestoreSub?.cancel();
    _firestoreSub = repo.watchCallSession(sessionId).listen(
      (session) async {
        switch (session.status) {
          case CallStatus.active:
            // Receiver is already connected to WS (they connected before
            // updating Firestore). Cancel ringing timer and connect our WS.
            _ringingTimer?.cancel();

            state = AsyncData(CallState(
              phase:           CallPhase.connecting,
              sessionId:       sessionId,
              session:         session,
              myLanguage:      myLanguage,
              partnerLanguage: partnerLanguage,
            ));

            try {
              await _connectAndStartAudio(
                sessionId:       sessionId,
                myLanguage:      myLanguage,
                partnerLanguage: partnerLanguage,
              );
              _startConnectingTimeout(sessionId);
            } catch (e) {
              debugPrint('[CallController] Caller WS connect error: $e');
              _handleWsFatalError('Connection failed. Please try again.');
            }

          case CallStatus.declined:
            _ringingTimer?.cancel();
            await _cleanup();
            state = const AsyncData(
              CallState(phase: CallPhase.ended, error: 'Call was declined'),
            );
            await Future.delayed(const Duration(seconds: 2));
            state = const AsyncData(CallState());

          case CallStatus.ended:
            await _cleanup();
            state = const AsyncData(CallState(phase: CallPhase.ended));
            await Future.delayed(const Duration(seconds: 2));
            state = const AsyncData(CallState());

          case CallStatus.missed:
            await _cleanup();
            state = const AsyncData(
              CallState(phase: CallPhase.ended, error: 'No answer'),
            );
            await Future.delayed(const Duration(seconds: 2));
            state = const AsyncData(CallState());

          default:
            break;
        }
      },
      onError: (Object e) =>
          debugPrint('[CallController] Firestore watch error: $e'),
    );
  }

  // ── Internal: connect WS + mic + playback ─────────────────────────────────

  Future<void> _connectAndStartAudio({
    required String sessionId,
    required CallLanguage myLanguage,
    required CallLanguage partnerLanguage,
  }) async {
    final repo = ref.read(translateCallRepositoryProvider);

    await repo.connectWebSocket(
      sessionId:       sessionId,
      myLanguage:      myLanguage,
      partnerLanguage: partnerLanguage,
    );

    _wsEventSub?.cancel();
    _wsEventSub = repo.wsEvents.listen(
      _handleWsEvent,
      onError: (Object e) {
        debugPrint('[CallController] WS stream error: $e');
        _handleWsFatalError('Connection lost. Please try again.');
      },
    );

    await _startPlayback();
    await _startRecording();
  }

  // ── WebSocket event handler ───────────────────────────────────────────────

  void _handleWsEvent(WsEvent event) {
    final current = state.valueOrNull ?? const CallState();

    switch (event) {
      case WsConnectedEvent():
        debugPrint('[CallController] WS connected, awaiting call_started');

      case WsCallStartedEvent():
        _connectingTimeoutTimer?.cancel();
        _callStartTime = DateTime.now();
        _startCallTimer();
        state = AsyncData(current.copyWith(
          phase: CallPhase.active,
          error: null,
        ));
        debugPrint('[CallController] Call active');

      case WsTranscriptEvent(:final text, :final isFinal, :final lang):
        final isMe = lang == current.myLanguage?.sourceLang;
        if (isMe) {
          state = AsyncData(current.copyWith(myTranscript: text));
          if (isFinal) _clearTranscriptAfterDelay(mine: true);
        } else {
          state = AsyncData(current.copyWith(partnerTranscript: text));
          if (isFinal) _clearTranscriptAfterDelay(mine: false);
        }

      case WsAudioEvent(:final pcmBytes):
        _audioQueue.add(pcmBytes);

      case WsPartnerLeftEvent():
        debugPrint('[CallController] Partner left');
        hangUp();

      case WsErrorEvent(:final code, :final message):
        debugPrint('[WS] $code: $message');
        const fatalCodes = {'SESSION_NOT_FOUND', 'AUTH_FAILED', 'WS_ERROR'};
        if (fatalCodes.contains(code)) {
          _handleWsFatalError(message);
        } else {
          state = AsyncData(current.copyWith(error: message));
        }
    }
  }

  // ── Connecting timeout ────────────────────────────────────────────────────

  void _startConnectingTimeout(String sessionId) {
    _connectingTimeoutTimer?.cancel();
    _connectingTimeoutTimer = Timer(
      const Duration(seconds: 30),
      () {
        if (state.valueOrNull?.phase == CallPhase.connecting) {
          debugPrint('[CallController] Connecting timeout');
          _handleWsFatalError('Could not connect. Please try again.');
        }
      },
    );
  }

  void _handleWsFatalError(String message) {
    final sessionId = state.valueOrNull?.sessionId;
    _cleanup().then((_) async {
      if (sessionId != null) {
        try {
          final repo = ref.read(translateCallRepositoryProvider);
          await repo.updateCallStatus(sessionId, CallStatus.ended,
              endedAt: DateTime.now());
          await repo.endBackendSession(sessionId);
        } catch (_) {}
      }
      state = AsyncData(CallState(phase: CallPhase.ended, error: message));
      await Future.delayed(const Duration(seconds: 3));
      if (state.valueOrNull?.phase == CallPhase.ended) {
        state = const AsyncData(CallState());
      }
    });
  }

  void _clearTranscriptAfterDelay({required bool mine}) {
    Future.delayed(const Duration(seconds: 3), () {
      final s = state.valueOrNull;
      if (s == null) return;
      state = AsyncData(
        mine ? s.copyWith(myTranscript: '') : s.copyWith(partnerTranscript: ''),
      );
    });
  }

  // ── Audio ─────────────────────────────────────────────────────────────────

  Future<void> _startPlayback() async {
    final source = _PcmStreamAudioSource(_audioQueue.stream);
    await _player.setAudioSource(source);
    await _player.play();
  }

  Future<void> _startRecording() async {
    final repo   = ref.read(translateCallRepositoryProvider);
    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder:     AudioEncoder.pcm16bits,
        sampleRate:  AppConstants.audioSampleRate,
        numChannels: 1,
      ),
    );
    _audioStreamSub = stream.listen((chunk) {
      if (state.valueOrNull?.isMuted == true) return;
      repo.sendAudio(Uint8List.fromList(chunk));
    });
  }

  void _startCallTimer() {
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final s = state.valueOrNull;
      if (s == null || !s.isActive) return;
      state = AsyncData(s.copyWith(
        callDuration: s.callDuration + const Duration(seconds: 1),
      ));
    });
  }

  Future<void> _handleMissed(String sessionId) async {
    if (state.valueOrNull?.phase != CallPhase.ringingOutgoing) return;
    try {
      final repo = ref.read(translateCallRepositoryProvider);
      await repo.updateCallStatus(sessionId, CallStatus.missed);
    } catch (e) {
      debugPrint('[CallController] _handleMissed error: $e');
    }
    await _cleanup();
    state = const AsyncData(CallState(phase: CallPhase.ended, error: 'No answer'));
    await Future.delayed(const Duration(seconds: 2));
    state = const AsyncData(CallState());
  }

  Future<bool> _requestMic() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> _cleanup() async {
    _callTimer?.cancel();
    _ringingTimer?.cancel();
    _connectingTimeoutTimer?.cancel();
    _firestoreSub?.cancel();
    _wsEventSub?.cancel();
    _audioStreamSub?.cancel();

    try { await _recorder.stop(); } catch (_) {}
    try { await _player.stop();   } catch (_) {}

    try {
      final repo = ref.read(translateCallRepositoryProvider);
      await repo.disconnectWebSocket();
    } catch (_) {}

    _callTimer              = null;
    _ringingTimer           = null;
    _connectingTimeoutTimer = null;
    _firestoreSub           = null;
    _wsEventSub             = null;
    _audioStreamSub         = null;
    _callStartTime          = null;
  }

  static String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('permission-denied')) {
      return 'Permission denied. Check Firestore security rules.';
    }
    if (msg.contains('network') || msg.contains('unavailable')) {
      return 'Network error. Check your connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}

// ── Custom just_audio source for raw PCM stream ───────────────────────────────

class _PcmStreamAudioSource extends StreamAudioSource {
  _PcmStreamAudioSource(this._stream);
  final Stream<Uint8List> _stream;

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    return StreamAudioResponse(
      sourceLength:  null,
      contentLength: null,
      offset:        start ?? 0,
      contentType:   'audio/raw',
      stream:        _stream,
    );
  }
}