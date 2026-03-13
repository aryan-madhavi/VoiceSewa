import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/call_repository.dart';
import '../domain/call_state.dart';
import '../../../core/providers/language_provider.dart';

// ── BCP-47 language code mapping ───────────────────────────────────────────────

const _localeToBcp47 = {
  'en': 'en-US',
  'hi': 'hi-IN',
  'mr': 'mr-IN',
  'gu': 'gu-IN',
};

// ── Transcript list ────────────────────────────────────────────────────────────

class TranscriptsNotifier extends Notifier<List<TranscriptEntry>> {
  @override
  List<TranscriptEntry> build() => [];

  void add(TranscriptEntry entry) {
    state = [...state, entry];
  }

  void clear() => state = [];
}

final transcriptsProvider =
    NotifierProvider<TranscriptsNotifier, List<TranscriptEntry>>(
  TranscriptsNotifier.new,
);

// ── Call controller ────────────────────────────────────────────────────────────

class CallController extends AsyncNotifier<CallPhase> {
  Timer? _connectingTimer;

  @override
  Future<CallPhase> build() async {
    // Read the UID directly from FirebaseAuth instead of watching a reactive
    // provider. Watching currentUserProvider causes build() to re-run on any
    // Firebase auth event (e.g. the token refresh triggered inside connect()),
    // which would reset state back to idle mid-call.
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      ref.listen(incomingCallProvider(uid), (_, next) {
        next.whenData((signal) {
          if (signal != null) _handleIncomingSignal(signal);
        });
      });
    }
    ref.onDispose(() => _connectingTimer?.cancel());
    return const CallPhase.idle();
  }

  CallRepository get _repo => ref.read(callRepositoryProvider);

  String _myLang() {
    final locale = ref.read(localeProvider);
    return _localeToBcp47[locale.languageCode] ?? 'en-US';
  }

  void _handleIncomingSignal(CallSignal signal) {
    if (state.asData?.value is IdlePhase) {
      state = AsyncData(CallPhase.incoming(
        sessionId: signal.sessionId,
        callerUid: signal.callerUid,
        callerLang: signal.callerLang,
      ));
    }
  }

  /// Place an outgoing call to [receiverUid].
  Future<void> startCall(String receiverUid) async {
    try {
      final lang = _myLang();
      final sessionId = await _repo.createSession(receiverUid, lang);
      state = AsyncData(CallPhase.outgoing(
        sessionId: sessionId,
        receiverUid: receiverUid,
      ));
      await _connectWs(sessionId, lang);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Accept an incoming call.
  Future<void> acceptCall(CallSignal signal) async {
    state = AsyncData(CallPhase.connecting(sessionId: signal.sessionId));
    try {
      await _repo.updateCallStatus(signal.sessionId, 'active');
      final lang = _myLang();
      await _connectWs(signal.sessionId, lang);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Decline an incoming call without answering.
  Future<void> declineCall(String sessionId) async {
    try {
      await _repo.updateCallStatus(sessionId, 'ended');
    } catch (_) {
      // Best effort — always transition to idle so the UI clears.
    }
    state = const AsyncData(CallPhase.idle());
  }

  /// Hang up the active call.
  Future<void> endCall() async {
    _connectingTimer?.cancel();
    final current = state.asData?.value;
    final sessionId = switch (current) {
      OutgoingPhase(:final sessionId) => sessionId,
      ConnectingPhase(:final sessionId) => sessionId,
      ActivePhase(:final sessionId) => sessionId,
      _ => null,
    };
    if (sessionId != null) {
      await _repo.endSession(sessionId);
    }
    ref.read(transcriptsProvider.notifier).clear();
    state = const AsyncData(CallPhase.ended());
    await Future.delayed(const Duration(seconds: 2));
    state = const AsyncData(CallPhase.idle());
  }

  Future<void> _connectWs(String sessionId, String lang) async {
    await _repo.connect(
      sessionId: sessionId,
      lang: lang,
      onTranscript: (entry) {
        ref.read(transcriptsProvider.notifier).add(entry);
      },
      onPhase: (type) {
        switch (type) {
          case 'call_started':
            _connectingTimer?.cancel();
            unawaited(_repo.updateCallStatus(sessionId, 'active'));
            state = AsyncData(CallPhase.active(sessionId: sessionId));
          case 'partner_left':
            _connectingTimer?.cancel();
            _handlePartnerLeft(sessionId);
          case 'disconnected':
          case 'error':
            _connectingTimer?.cancel();
            unawaited(_repo.disconnect());
            state = const AsyncData(CallPhase.ended(reason: 'Connection lost'));
        }
      },
    );

    // If the partner's WebSocket is gone, the backend will never send
    // call_started. Bail out after 30 s.
    _connectingTimer?.cancel();
    _connectingTimer = Timer(const Duration(seconds: 30), () {
      if (state.asData?.value is ConnectingPhase) {
        unawaited(_repo.disconnect());
        state = const AsyncData(CallPhase.ended(reason: 'Partner did not connect'));
      }
    });
  }

  void _handlePartnerLeft(String sessionId) {
    unawaited(_repo.endSession(sessionId));
    ref.read(transcriptsProvider.notifier).clear();
    state = const AsyncData(CallPhase.ended(reason: 'Partner left the call'));
  }
}

final callControllerProvider =
    AsyncNotifierProvider<CallController, CallPhase>(CallController.new);
