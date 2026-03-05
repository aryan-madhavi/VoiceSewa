// lib/features/translate_call/application/call_controller.dart
//
// The core of the feature. AsyncNotifier<CallState> that owns:
//
//   ┌─ Lifecycle ──────────────────────────────────────────────────────────────
//   │  initiateCall()  — caller side: create backend session, write Firestore,
//   │                    watch for receiver accepting
//   │  acceptCall()    — receiver side: update Firestore, connect WebSocket
//   │  declineCall()   — receiver side: update Firestore status
//   │  hangUp()        — either side: disconnect everything, update Firestore
//   │  toggleMute()    — pause / resume microphone recording
//   └──────────────────────────────────────────────────────────────────────────
//
//   ┌─ Audio ──────────────────────────────────────────────────────────────────
//   │  Microphone   → record package streams PCM16 @ 16 kHz
//   │  Backend      → WS binary frames → just_audio _PcmStreamAudioSource
//   └──────────────────────────────────────────────────────────────────────────
//
//   ┌─ State machine ──────────────────────────────────────────────────────────
//   │  idle → ringingOutgoing / ringingIncoming → connecting → active → ended
//   └──────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants.dart';
import '../data/translate_call_repository.dart';
import '../domain/call_language.dart';
import '../domain/call_session.dart';
import 'providers.dart';

// ── CallPhase ─────────────────────────────────────────────────────────────────

enum CallPhase {
  idle,
  ringingOutgoing, // Caller waiting — receiver being notified via FCM
  ringingIncoming, // Receiver seeing incoming call screen
  connecting,      // WebSocket handshake in progress
  active,          // Both users connected, translation pipeline running
  ended,           // Call finished — brief summary state before returning idle
}

// ── CallState ─────────────────────────────────────────────────────────────────

class CallState {
  const CallState({
    this.phase           = CallPhase.idle,
    this.sessionId,
    this.session,
    this.myLanguage,
    this.partnerLanguage,
    this.myTranscript    = '',
    this.partnerTranscript = '',
    this.isMuted         = false,
    this.callDuration    = Duration.zero,
    this.error,
  });

  final CallPhase phase;
  final String? sessionId;
  final CallSession? session;
  final CallLanguage? myLanguage;
  final CallLanguage? partnerLanguage;

  /// Live STT caption of what I am saying (interim + final from backend)
  final String myTranscript;

  /// Live STT caption of what the partner is saying
  final String partnerTranscript;

  final bool isMuted;
  final Duration callDuration;

  /// Non-null when a recoverable error occurred (e.g. mic permission denied).
  final String? error;

  bool get isActive   => phase == CallPhase.active;
  bool get isRinging  => phase == CallPhase.ringingOutgoing ||
                         phase == CallPhase.ringingIncoming;
  bool get isIdle     => phase == CallPhase.idle;

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
        error:             error,           // null clears the error — intentional
      );
}

// ── Controller ────────────────────────────────────────────────────────────────

class CallController extends AsyncNotifier<CallState> {
  // ── Resources ─────────────────────────────────────────────────────────────
  final _recorder   = AudioRecorder();
  final _player     = AudioPlayer();
  final _uuid       = const Uuid();

  // PCM chunks from backend are pushed here; _PcmStreamAudioSource reads them
  final _audioQueue = StreamController<Uint8List>.broadcast();

  // Active subscriptions
  StreamSubscription<WsEvent>?   _wsEventSub;
  StreamSubscription<List<int>>? _audioStreamSub;
  StreamSubscription<CallSession>? _firestoreSub;

  // Timers
  Timer? _callTimer;
  Timer? _ringingTimer;

  DateTime? _callStartTime;

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Future<CallState> build() async {
    ref.onDispose(_cleanup);
    return const CallState();
  }

  // ── Public actions ────────────────────────────────────────────────────────

  /// Caller initiates a call to [receiverUid].
  Future<void> initiateCall({
    required String receiverUid,
    required String receiverName,
    required String receiverFcmToken,
    required CallLanguage myLanguage,
    required CallLanguage partnerLanguage,
  }) async {
    state = const AsyncLoading();

    try {
      // 1. Microphone permission
      final micOk = await _requestMic();
      if (!micOk) {
        state = AsyncData(const CallState(
          error: 'Microphone permission is required to make calls.',
        ));
        return;
      }

      final repo = ref.read(translateCallRepositoryProvider);
      final user = ref.read(firebaseAuthProvider).currentUser!;

      // 2. Create backend session — returns the sessionId
      final sessionId = await repo.createBackendSession();

      // 3. Write Firestore call doc (triggers Cloud Function → FCM to receiver)
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

      // 4. Watch Firestore for receiver accepting / declining
      _watchForAnswer(sessionId, myLanguage, partnerLanguage);

      // 5. Auto-miss after timeout
      _ringingTimer = Timer(AppConstants.ringingTimeout, () {
        _handleMissed(sessionId);
      });
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Receiver accepts an incoming call.
  Future<void> acceptCall({
    required CallSession incomingSession,
    required CallLanguage myLanguage,
  }) async {
    state = const AsyncLoading();

    try {
      final micOk = await _requestMic();
      if (!micOk) {
        state = AsyncData(const CallState(
          error: 'Microphone permission required.',
        ));
        return;
      }

      final repo          = ref.read(translateCallRepositoryProvider);
      final partnerLang   = CallLanguage.fromSourceLang(incomingSession.callerLang);
      final notifications = ref.read(notificationServiceProvider);

      // Dismiss the heads-up notification
      await notifications.dismissIncomingCall(incomingSession.sessionId);

      // Update Firestore → caller's watchCallSession emits active
      await repo.updateCallStatus(incomingSession.sessionId, CallStatus.active);

      state = AsyncData(CallState(
        phase:           CallPhase.connecting,
        sessionId:       incomingSession.sessionId,
        session:         incomingSession,
        myLanguage:      myLanguage,
        partnerLanguage: partnerLang,
      ));

      await _connectAndStartAudio(
        sessionId:       incomingSession.sessionId,
        myLanguage:      myLanguage,
        partnerLanguage: partnerLang,
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Receiver declines an incoming call.
  Future<void> declineCall(String sessionId) async {
    final repo          = ref.read(translateCallRepositoryProvider);
    final notifications = ref.read(notificationServiceProvider);

    await notifications.dismissIncomingCall(sessionId);
    await repo.updateCallStatus(sessionId, CallStatus.declined);

    state = const AsyncData(CallState());
  }

  /// Either side hangs up the active or ringing call.
  Future<void> hangUp() async {
    final current    = state.valueOrNull;
    final sessionId  = current?.sessionId;
    final startTime  = _callStartTime;
    final session    = current?.session;

    _ringingTimer?.cancel();
    await _cleanup();

    if (sessionId != null) {
      final repo     = ref.read(translateCallRepositoryProvider);
      final duration = startTime != null
          ? DateTime.now().difference(startTime).inSeconds
          : null;

      await repo.updateCallStatus(
        sessionId,
        CallStatus.ended,
        endedAt:         DateTime.now(),
        durationSeconds: duration,
      );

      // Update history entries for both participants
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
    }

    state = const AsyncData(CallState(phase: CallPhase.ended));

    // Return to idle after a brief summary pause
    await Future.delayed(const Duration(seconds: 2));
    if (state.valueOrNull?.phase == CallPhase.ended) {
      state = const AsyncData(CallState());
    }
  }

  /// Toggle microphone mute. No-op when call is not active.
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
            // Receiver accepted
            _ringingTimer?.cancel();
            state = AsyncData(CallState(
              phase:           CallPhase.connecting,
              sessionId:       sessionId,
              session:         session,
              myLanguage:      myLanguage,
              partnerLanguage: partnerLanguage,
            ));
            await _connectAndStartAudio(
              sessionId:       sessionId,
              myLanguage:      myLanguage,
              partnerLanguage: partnerLanguage,
            );

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

          default:
            break;
        }
      },
      onError: (Object e) => debugPrint('[CallController] Firestore error: $e'),
    );
  }

  // ── Internal: connect WebSocket + mic + playback ──────────────────────────

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
    _wsEventSub = repo.wsEvents.listen(_handleWsEvent);

    await _startPlayback();
    await _startRecording();
  }

  // ── WebSocket event handler ───────────────────────────────────────────────

  void _handleWsEvent(WsEvent event) {
    final current = state.valueOrNull ?? const CallState();

    switch (event) {
      case WsConnectedEvent():
        // Wait for call_started before going active
        break;

      case WsCallStartedEvent():
        _callStartTime = DateTime.now();
        _startCallTimer();
        state = AsyncData(current.copyWith(phase: CallPhase.active));

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
        hangUp();

      case WsErrorEvent(:final code, :final message):
        debugPrint('[WS] $code: $message');
        // Non-fatal: surface to UI but keep call alive
        state = AsyncData(current.copyWith(error: message));
    }
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

  // ── Audio: playback ───────────────────────────────────────────────────────

  Future<void> _startPlayback() async {
    final source = _PcmStreamAudioSource(_audioQueue.stream);
    await _player.setAudioSource(source);
    await _player.play();
  }

  // ── Audio: recording ──────────────────────────────────────────────────────

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

  // ── Timer helpers ─────────────────────────────────────────────────────────

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
    final repo = ref.read(translateCallRepositoryProvider);
    await repo.updateCallStatus(sessionId, CallStatus.missed);
    await _cleanup();
    state = const AsyncData(
      CallState(phase: CallPhase.ended, error: 'No answer'),
    );
    await Future.delayed(const Duration(seconds: 2));
    state = const AsyncData(CallState());
  }

  // ── Permissions ───────────────────────────────────────────────────────────

  Future<bool> _requestMic() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  // ── Cleanup ───────────────────────────────────────────────────────────────

  Future<void> _cleanup() async {
    _callTimer?.cancel();
    _ringingTimer?.cancel();
    _firestoreSub?.cancel();
    _wsEventSub?.cancel();
    _audioStreamSub?.cancel();

    await _recorder.stop();
    await _player.stop();

    final repo = ref.read(translateCallRepositoryProvider);
    await repo.disconnectWebSocket();

    _callTimer      = null;
    _ringingTimer   = null;
    _firestoreSub   = null;
    _wsEventSub     = null;
    _audioStreamSub = null;
    _callStartTime  = null;
  }
}

// ── Custom just_audio source for raw PCM stream ───────────────────────────────
// just_audio doesn't support raw PCM out of the box, so we wrap the
// incoming audio chunk stream in a StreamAudioSource.

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