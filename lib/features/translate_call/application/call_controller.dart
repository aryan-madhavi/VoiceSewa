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
  ringingOutgoing, // Caller waiting — receiver notified via FCM
  ringingIncoming, // Receiver on incoming-call screen
  connecting,      // WS handshake in progress, waiting for call_started
  active,          // Both connected, translation pipeline running
  ended,           // Brief ended state before returning to idle
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

  final CallPhase     phase;
  final String?       sessionId;
  final CallSession?  session;
  final CallLanguage? myLanguage;
  final CallLanguage? partnerLanguage;
  final String        myTranscript;
  final String        partnerTranscript;
  final bool          isMuted;
  final Duration      callDuration;
  final String?       error;

  bool get isActive  => phase == CallPhase.active;
  bool get isRinging => phase == CallPhase.ringingOutgoing ||
                        phase == CallPhase.ringingIncoming;
  bool get isIdle    => phase == CallPhase.idle;

  CallState copyWith({
    CallPhase?    phase,
    String?       sessionId,
    CallSession?  session,
    CallLanguage? myLanguage,
    CallLanguage? partnerLanguage,
    String?       myTranscript,
    String?       partnerTranscript,
    bool?         isMuted,
    Duration?     callDuration,
    String?       error,
  }) =>
      CallState(
        phase:             phase             ?? this.phase,
        sessionId:         sessionId         ?? this.sessionId,
        session:           session           ?? this.session,
        myLanguage:        myLanguage        ?? this.myLanguage,
        partnerLanguage:   partnerLanguage   ?? this.partnerLanguage,
        myTranscript:      myTranscript      ?? this.myTranscript,
        partnerTranscript: partnerTranscript ?? this.partnerTranscript,
        isMuted:           isMuted           ?? this.isMuted,
        callDuration:      callDuration      ?? this.callDuration,
        error:             error,
      );
}

// ── Controller ────────────────────────────────────────────────────────────────

class CallController extends AsyncNotifier<CallState> {
  final _recorder = AudioRecorder();

  // just_audio player — receives WAV-wrapped PCM chunks via _WavStreamAudioSource.
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

    // FIX: Clean up any stale ringing docs left over from previous crashed
    // or failed calls. Without this, watchIncomingCall picks them up on every
    // app start and routes both phones to the call screen automatically.
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user != null) {
      try {
        await ref
            .read(translateCallRepositoryProvider)
            .cleanupStaleRingingCalls(user.uid);
      } catch (e) {
        debugPrint('[CallController] stale call cleanup error: $e');
      }
    }

    return const CallState();
  }

  // ── Initiate call (caller) ────────────────────────────────────────────────

  Future<void> initiateCall({
    required String       receiverUid,
    required String       receiverName,
    required CallLanguage myLanguage,
    required CallLanguage partnerLanguage,
  }) async {
    state = const AsyncLoading();

    try {
      final micOk = await _requestMic();
      if (!micOk) {
        state = AsyncData(const CallState(
            error: 'Microphone permission is required to make calls.'));
        return;
      }

      final repo = ref.read(translateCallRepositoryProvider);
      final user = ref.read(firebaseAuthProvider).currentUser!;

      final receiverFcmToken = await repo.fetchReceiverFcmToken(receiverUid);
      if (receiverFcmToken == null) {
        state = AsyncData(const CallState(
            error: 'Could not reach this contact. They may be offline.'));
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

      // FIX (Bug 3): Attach the Firestore watcher BEFORE setting state to
      // ringingOutgoing. This eliminates the race where the receiver accepts
      // while the listener is still being attached, causing the caller to miss
      // the status=active update and sit on ringingOutgoing until timeout.
      _watchForAnswer(sessionId, myLanguage, partnerLanguage);

      await repo.createCallDoc(session);

      state = AsyncData(CallState(
        phase:           CallPhase.ringingOutgoing,
        sessionId:       sessionId,
        session:         session,
        myLanguage:      myLanguage,
        partnerLanguage: partnerLanguage,
      ));

      _ringingTimer = Timer(AppConstants.ringingTimeout, () {
        _handleMissed(sessionId);
      });
    } catch (e, st) {
      debugPrint('[CallController] initiateCall error: $e\n$st');
      state = AsyncData(CallState(error: _friendlyError(e)));
    }
  }

  // ── Accept call (receiver) ────────────────────────────────────────────────
  //
  // ORDER IS CRITICAL — see inline comments.

  Future<void> acceptCall({
    required CallSession  incomingSession,
    required CallLanguage myLanguage,
  }) async {
    try {
      final micOk = await _requestMic();
      if (!micOk) {
        state = AsyncData(const CallState(
            error: 'Microphone permission required.'));
        return;
      }

      final repo          = ref.read(translateCallRepositoryProvider);
      // FIX (Bug 1 / display): The receiver's partner is the CALLER,
      // so partnerLanguage must be derived from callerLang, not receiverLang.
      final partnerLang   = CallLanguage.fromSourceLang(incomingSession.callerLang);
      final notifications = ref.read(notificationServiceProvider);

      await notifications.dismissIncomingCall(incomingSession.sessionId);

      // 1. Connect WS — receiver joins session first
      await _connectAndStartAudio(
        sessionId:       incomingSession.sessionId,
        myLanguage:      myLanguage,
        partnerLanguage: partnerLang,
      );
      debugPrint('[CallController] receiver WS connected ok');

      // 2. Signal caller — they will now connect their own WS
      await repo.updateCallStatus(incomingSession.sessionId, CallStatus.active);
      debugPrint('[CallController] Firestore status=active written');

      // 3. Transition to connecting — router moves to /active-call
      //    (WS already live so call_started can arrive immediately)
      state = AsyncData(CallState(
        phase:           CallPhase.connecting,
        sessionId:       incomingSession.sessionId,
        session:         incomingSession,
        myLanguage:      myLanguage,
        partnerLanguage: partnerLang,
      ));

      _startConnectingTimeout(incomingSession.sessionId);

    } catch (e, st) {
      debugPrint('[CallController] acceptCall error: $e\n$st');
      await _cleanup();
      state = AsyncData(CallState(
        phase: CallPhase.ended,
        error: _friendlyError(e),
      ));
      await Future.delayed(const Duration(seconds: 3));
      state = const AsyncData(CallState());
    }
  }

  // ── Decline call (receiver) ───────────────────────────────────────────────

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
    if (muted) { _recorder.pause(); } else { _recorder.resume(); }
    state = AsyncData(current.copyWith(isMuted: muted));
  }

  // ── Watch Firestore for receiver response (caller side) ───────────────────

  void _watchForAnswer(
    String       sessionId,
    CallLanguage myLanguage,
    CallLanguage partnerLanguage,
  ) {
    final repo = ref.read(translateCallRepositoryProvider);

    _firestoreSub?.cancel();
    _firestoreSub = repo.watchCallSession(sessionId).listen(
      (session) async {
        switch (session.status) {

          case CallStatus.active:
            // Receiver's WS is already connected. Safe to connect now.
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
              debugPrint('[CallController] caller WS connect error: $e');
              _handleWsFatalError('Connection failed. Please try again.');
            }

          case CallStatus.declined:
            _ringingTimer?.cancel();
            await _cleanup();
            state = const AsyncData(
                CallState(phase: CallPhase.ended, error: 'Call was declined'));
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
                CallState(phase: CallPhase.ended, error: 'No answer'));
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

  // ── Connect WS + mic + playback ───────────────────────────────────────────

  Future<void> _connectAndStartAudio({
    required String       sessionId,
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

  // ── WS event handler ─────────────────────────────────────────────────────

  void _handleWsEvent(WsEvent event) {
    final current = state.valueOrNull ?? const CallState();

    switch (event) {
      case WsConnectedEvent():
        debugPrint('[CallController] WS connected, awaiting call_started');

      case WsCallStartedEvent():
        _connectingTimeoutTimer?.cancel();
        _callStartTime = DateTime.now();
        _startCallTimer();
        state = AsyncData(current.copyWith(phase: CallPhase.active, error: null));
        debugPrint('[CallController] call active');

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
        // Feed raw PCM into the queue — _WavStreamAudioSource wraps each
        // chunk with a WAV header so just_audio can decode it.
        _audioQueue.add(pcmBytes);

      case WsPartnerLeftEvent():
        debugPrint('[CallController] partner left');
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
    _connectingTimeoutTimer = Timer(const Duration(seconds: 30), () {
      if (state.valueOrNull?.phase == CallPhase.connecting) {
        debugPrint('[CallController] connecting timeout');
        _handleWsFatalError('Could not connect. Please try again.');
      }
    });
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

  // FIX (Bug 2): just_audio's StreamAudioSource requires a decodable audio
  // container — it cannot play raw PCM with contentType:'audio/raw'.
  // The fix is to keep just_audio but wrap each incoming PCM chunk with a
  // minimal WAV header before handing it to the stream. _WavStreamAudioSource
  // (defined at the bottom of this file) does this transparently.
  // No dependency change needed — just_audio stays in pubspec.yaml as-is.
  Future<void> _startPlayback() async {
    final source = _WavStreamAudioSource(
      _audioQueue.stream,
      sampleRate:  AppConstants.audioSampleRate,
      numChannels: 1,
      bitDepth:    16,
    );
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
      state = AsyncData(
          s.copyWith(callDuration: s.callDuration + const Duration(seconds: 1)));
    });
  }

  Future<void> _handleMissed(String sessionId) async {
    if (state.valueOrNull?.phase != CallPhase.ringingOutgoing) return;
    try {
      await ref
          .read(translateCallRepositoryProvider)
          .updateCallStatus(sessionId, CallStatus.missed);
    } catch (e) {
      debugPrint('[CallController] _handleMissed error: $e');
    }
    await _cleanup();
    state = const AsyncData(
        CallState(phase: CallPhase.ended, error: 'No answer'));
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

    // Stop just_audio player cleanly
    try { await _player.stop(); } catch (_) {}

    try { await _recorder.stop(); } catch (_) {}

    try {
      await ref.read(translateCallRepositoryProvider).disconnectWebSocket();
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

// ── WAV-wrapping stream audio source for just_audio ───────────────────────────
//
// just_audio's StreamAudioSource requires a decodable container format.
// Raw PCM bytes (what the backend sends) have no header, so just_audio
// produces silence or throws. The fix: prepend a WAV header to each chunk.
//
// WAV format for our stream:
//   - PCM16 (linear, little-endian)
//   - 16 000 Hz sample rate
//   - 1 channel (mono)

class _WavStreamAudioSource extends StreamAudioSource {
  _WavStreamAudioSource(
    this._pcmStream, {
    required this.sampleRate,
    required this.numChannels,
    required this.bitDepth,
  });

  final Stream<Uint8List> _pcmStream;
  final int sampleRate;
  final int numChannels;
  final int bitDepth;

  // Builds a 44-byte WAV header. Because total length is unknown at stream
  // start we write the length of *this chunk only* — each chunk is a
  // self-contained, valid WAV that just_audio can decode independently.
  Uint8List _wavHeader(int pcmDataLength) {
    final byteRate   = sampleRate * numChannels * (bitDepth ~/ 8);
    final blockAlign = numChannels * (bitDepth ~/ 8);
    final totalSize  = pcmDataLength + 36;

    final h = ByteData(44);
    // RIFF
    h.setUint8(0,  0x52); h.setUint8(1,  0x49);
    h.setUint8(2,  0x46); h.setUint8(3,  0x46);
    h.setUint32(4, totalSize,    Endian.little);
    // WAVE
    h.setUint8(8,  0x57); h.setUint8(9,  0x41);
    h.setUint8(10, 0x56); h.setUint8(11, 0x45);
    // fmt
    h.setUint8(12, 0x66); h.setUint8(13, 0x6D);
    h.setUint8(14, 0x74); h.setUint8(15, 0x20);
    h.setUint32(16, 16,           Endian.little); // sub-chunk size
    h.setUint16(20, 1,            Endian.little); // PCM
    h.setUint16(22, numChannels,  Endian.little);
    h.setUint32(24, sampleRate,   Endian.little);
    h.setUint32(28, byteRate,     Endian.little);
    h.setUint16(32, blockAlign,   Endian.little);
    h.setUint16(34, bitDepth,     Endian.little);
    // data
    h.setUint8(36, 0x64); h.setUint8(37, 0x61);
    h.setUint8(38, 0x74); h.setUint8(39, 0x61);
    h.setUint32(40, pcmDataLength, Endian.little);

    return h.buffer.asUint8List();
  }

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final wrappedStream = _pcmStream.map((pcm) {
      final wav = Uint8List(44 + pcm.length);
      wav.setAll(0, _wavHeader(pcm.length));
      wav.setAll(44, pcm);
      return wav;
    });

    return StreamAudioResponse(
      sourceLength:  null,
      contentLength: null,
      offset:        start ?? 0,
      contentType:   'audio/wav',
      stream:        wrappedStream,
    );
  }
}