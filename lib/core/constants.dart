// lib/core/constants.dart
//
// Single source of truth for all configuration constants.
// When integrating into your main app, merge these into your
// existing constants file and update backendBaseUrl if the
// Cloud Run service URL ever changes after a redeploy.

abstract final class AppConstants {
  // ── Backend ───────────────────────────────────────────────────────────────
  // Production Cloud Run service — asia-south1 (Mumbai)
  static const String backendBaseUrl =
      'https://voicesewa-call-translate-bzjis3bz3q-el.a.run.app';

  static const String backendWsUrl =
      'wss://voicesewa-call-translate-bzjis3bz3q-el.a.run.app/ws';

  // ── Firestore collections ─────────────────────────────────────────────────
  static const String callsCollection           = 'calls';
  static const String usersCollection           = 'users';
  static const String callHistorySubcollection  = 'call_history';

  // ── FCM data message types ────────────────────────────────────────────────
  static const String fcmTypeIncomingCall = 'incoming_call';
  static const String fcmTypeCallEnded    = 'call_ended';
  static const String fcmTypeCallDeclined = 'call_declined';

  // ── Android notification channel ─────────────────────────────────────────
  static const String callChannelId   = 'voicesewa_calls';
  static const String callChannelName = 'Incoming Calls';
  static const String callChannelDesc =
      'Ringing notifications for incoming translated calls';

  // ── Call behaviour ────────────────────────────────────────────────────────
  /// How long to ring before auto-marking the call as missed
  static const Duration ringingTimeout = Duration(seconds: 30);

  /// WebSocket keep-alive ping interval — prevents Cloud Run idle timeout
  static const Duration wsPingInterval = Duration(seconds: 20);

  // ── Audio ─────────────────────────────────────────────────────────────────
  /// PCM16 sample rate — matches Google STT + TTS config on the backend
  static const int audioSampleRate = 16000;

  // ── Session TTL (must match backend SESSION_TTL_MS) ───────────────────────
  static const Duration sessionTtl = Duration(hours: 2);
}