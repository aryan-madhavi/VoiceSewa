// lib/features/translate_call/data/notification_service.dart
//
// Singleton that owns flutter_local_notifications for the call feature.
//
// Tap scenarios handled:
//   A) App FOREGROUND  — user sees banner, taps it
//      → onDidReceiveNotificationResponse fires on main isolate
//      → _onTapForeground() → _onNotificationTap callback → router refresh
//
//   B) App BACKGROUND  — user taps notification in shade
//      → onDidReceiveNotificationResponse fires on main isolate (same as A)
//
//   C) App TERMINATED  — user taps notification, app cold-starts
//      → getNotificationAppLaunchDetails() checked in _handleLaunchNotification()
//      → called from init() which is re-called after ProviderScope is ready
//
// The _onNotificationTap callback is set by CallTranslateApp after ProviderScope
// is ready, so it can safely call ref.read() and trigger router navigation.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../../core/constants.dart';

// ── Payload ───────────────────────────────────────────────────────────────────

class CallNotificationPayload {
  const CallNotificationPayload({
    required this.sessionId,
    required this.callerUid,
    required this.callerName,
    required this.callerLang,
    required this.receiverLang,
  });

  final String sessionId;
  final String callerUid;
  final String callerName;
  final String callerLang;
  final String receiverLang;

  factory CallNotificationPayload.fromJson(Map<String, dynamic> j) =>
      CallNotificationPayload(
        sessionId:    j['sessionId']    as String,
        callerUid:    j['callerUid']    as String,
        callerName:   j['callerName']   as String,
        callerLang:   j['callerLang']   as String,
        receiverLang: j['receiverLang'] as String,
      );

  Map<String, dynamic> toJson() => {
        'sessionId':    sessionId,
        'callerUid':    callerUid,
        'callerName':   callerName,
        'callerLang':   callerLang,
        'receiverLang': receiverLang,
      };

  String encode() => jsonEncode(toJson());

  static CallNotificationPayload? tryDecode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return CallNotificationPayload.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[NotificationService] payload decode error: $e');
      return null;
    }
  }
}

// ── Service ───────────────────────────────────────────────────────────────────

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  // Tracks whether _plugin.initialize() has been called.
  bool _pluginInitialised = false;

  // Set by CallTranslateApp.initState() once ProviderScope is ready.
  // Receives the sessionId from a notification tap.
  void Function(String sessionId)? _onNotificationTap;

  // ── Register tap handler ──────────────────────────────────────────────────
  // Must be called before init() so that _handleLaunchNotification can use it.

  void setOnNotificationTap(void Function(String sessionId) handler) {
    _onNotificationTap = handler;
    debugPrint('[NotificationService] tap handler registered');
  }

  // ── Init ──────────────────────────────────────────────────────────────────
  // Called from:
  //   1. main() — early init so the Android channel exists
  //   2. _backgroundFcmHandler — background isolate (no tap handler here)
  //   3. CallTranslateApp.initState postFrameCallback — re-call after
  //      tap handler is registered, picks up launch notification

  Future<void> init() async {
    if (_pluginInitialised) {
      // Already initialised — just check for launch notification in case
      // the tap handler was registered after the first init() call.
      await _handleLaunchNotification();
      return;
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      // Fires when user taps notification while app is FOREGROUND or BACKGROUND
      onDidReceiveNotificationResponse: _onTapForeground,
      // Background isolate tap — can't navigate, just log
      onDidReceiveBackgroundNotificationResponse: _onTapBackground,
    );

    await _createCallChannel();
    _pluginInitialised = true;

    await _handleLaunchNotification();
  }

  // ── Launch detection (TERMINATED tap) ─────────────────────────────────────

  Future<void> _handleLaunchNotification() async {
    if (_onNotificationTap == null) return; // no handler yet — skip

    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return;

    final payload =
        CallNotificationPayload.tryDecode(details.notificationResponse?.payload);
    if (payload == null) return;

    debugPrint('[NotificationService] app launched by tap, '
        'sessionId=${payload.sessionId}');

    // Small delay to let the router settle after cold start
    await Future.delayed(const Duration(milliseconds: 600));
    _onNotificationTap?.call(payload.sessionId);
  }

  // ── Foreground / background tap ───────────────────────────────────────────

  void _onTapForeground(NotificationResponse response) {
    debugPrint('[NotificationService] tap (fg/bg), payload=${response.payload}');
    final payload = CallNotificationPayload.tryDecode(response.payload);
    if (payload == null) return;
    _onNotificationTap?.call(payload.sessionId);
  }

  // Must be top-level or static for the background isolate callback.
  @pragma('vm:entry-point')
  static void _onTapBackground(NotificationResponse response) {
    // Background isolate — cannot navigate. Foreground handler + launch
    // details cover all real navigation cases.
    debugPrint('[NotificationService] bg-isolate tap (no-op), '
        'payload=${response.payload}');
  }

  // ── Channel ───────────────────────────────────────────────────────────────

  Future<void> _createCallChannel() async {
    const channel = AndroidNotificationChannel(
      AppConstants.callChannelId,
      AppConstants.callChannelName,
      description:     AppConstants.callChannelDesc,
      importance:      Importance.max,
      playSound:       true,
      enableVibration: true,
      showBadge:       true,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // ── Show ──────────────────────────────────────────────────────────────────

  Future<void> showIncomingCall({
    required String sessionId,
    required String callerUid,
    required String callerName,
    required String callerLang,
    required String receiverLang,
  }) async {
    await init(); // safe to call multiple times

    final payload = CallNotificationPayload(
      sessionId:    sessionId,
      callerUid:    callerUid,
      callerName:   callerName,
      callerLang:   callerLang,
      receiverLang: receiverLang,
    );

    final androidDetails = AndroidNotificationDetails(
      AppConstants.callChannelId,
      AppConstants.callChannelName,
      channelDescription: AppConstants.callChannelDesc,
      importance:         Importance.max,
      priority:           Priority.max,
      category:           AndroidNotificationCategory.call,
      fullScreenIntent:   true,
      autoCancel:         false,
      ongoing:            true,
      ticker:             'Incoming call from $callerName',
      styleInformation:   BigTextStyleInformation(
        callerName,
        summaryText: 'Auto-translation enabled',
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert:      true,
      presentSound:      true,
      presentBanner:     true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    await _plugin.show(
      sessionId.hashCode,
      'Incoming Translated Call',
      callerName,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload.encode(),
    );
  }

  // ── Dismiss ───────────────────────────────────────────────────────────────

  Future<void> dismissIncomingCall(String sessionId) async {
    await _plugin.cancel(sessionId.hashCode);
  }

  Future<void> dismissAll() async {
    await _plugin.cancelAll();
  }
}