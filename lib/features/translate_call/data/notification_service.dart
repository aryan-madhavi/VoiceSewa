// lib/features/translate_call/data/notification_service.dart
//
// Wraps flutter_local_notifications.
// Responsible for:
//   - Creating the Android "Incoming Calls" high-priority channel on init
//   - Showing a full-screen / heads-up incoming call notification
//   - Dismissing it after the user accepts or declines
//   - Routing the user to the incoming call screen when they tap the notification
//
// This is a plain singleton — no Riverpod needed here because it must
// also be accessible from the top-level FCM background handler in main.dart
// (which runs before ProviderScope exists).

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../../core/constants.dart';

// ── Notification payload ──────────────────────────────────────────────────────

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

  factory CallNotificationPayload.fromJson(Map<String, dynamic> json) =>
      CallNotificationPayload(
        sessionId:    json['sessionId']    as String,
        callerUid:    json['callerUid']    as String,
        callerName:   json['callerName']   as String,
        callerLang:   json['callerLang']   as String,
        receiverLang: json['receiverLang'] as String,
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
      debugPrint('[NotificationService] Failed to decode payload: $e');
      return null;
    }
  }
}

// ── Service ───────────────────────────────────────────────────────────────────

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  // Whether the plugin has been initialised at least once.
  // The tap callback is stored separately so it survives re-init calls
  // from the background isolate (which can't navigate anyway).
  bool _pluginInitialised = false;

  // Callback registered by the app root. Called with sessionId when the
  // user taps an incoming call notification.
  void Function(String sessionId)? _onNotificationTap;

  // ── Register tap handler ──────────────────────────────────────────────────
  // Called once from CallTranslateApp.initState() with a handler that
  // can navigate via the router. Must be called AFTER ProviderScope is ready.

  void setOnNotificationTap(void Function(String sessionId) handler) {
    _onNotificationTap = handler;
  }

  // ── Init ──────────────────────────────────────────────────────────────────
  // Safe to call from both main() and the background FCM isolate.
  // The background isolate cannot navigate, so we only register the
  // onDidReceiveNotificationResponse when we have a tap handler registered.

  Future<void> init() async {
    if (_pluginInitialised) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS:     iosSettings,
      ),
      // This fires when the user taps a local notification while the app
      // is in the foreground OR when the app is opened via a notification tap.
      onDidReceiveNotificationResponse: _onTapForeground,
      // This fires when the notification is tapped while the app is in
      // the background (but not terminated) on older plugin versions.
      onDidReceiveBackgroundNotificationResponse: _onTapBackground,
    );

    await _createCallChannel();
    _pluginInitialised = true;

    // Check if the app was launched by tapping a notification while terminated
    await _handleLaunchNotification();
  }

  // ── Handle app launch from notification ───────────────────────────────────
  // When the app is fully terminated and the user taps the notification,
  // getNotificationAppLaunchDetails() returns the payload.

  Future<void> _handleLaunchNotification() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return;

    final payload = CallNotificationPayload.tryDecode(
        details.notificationResponse?.payload);
    if (payload == null) return;

    debugPrint('[NotificationService] App launched from notification: '
        'sessionId=${payload.sessionId}');

    // Delay slightly to allow ProviderScope / router to be ready
    await Future.delayed(const Duration(milliseconds: 500));
    _onNotificationTap?.call(payload.sessionId);
  }

  // ── Tap handlers ──────────────────────────────────────────────────────────

  void _onTapForeground(NotificationResponse response) {
    debugPrint('[NotificationService] Foreground tap, payload=${response.payload}');
    final payload = CallNotificationPayload.tryDecode(response.payload);
    if (payload == null) return;
    _onNotificationTap?.call(payload.sessionId);
  }

  // Top-level function required by flutter_local_notifications for background
  // tap handling. Must be annotated @pragma('vm:entry-point').
  // It cannot call instance methods directly, so it re-routes through the
  // singleton's stored callback.
  static void _onTapBackground(NotificationResponse response) {
    // This runs in a background isolate on some Android versions.
    // We can't navigate from here, but the foreground handler + launch
    // details cover all real cases. Log for debugging only.
    debugPrint('[NotificationService] Background tap, payload=${response.payload}');
  }

  // ── Channel setup ─────────────────────────────────────────────────────────

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

  // ── Show incoming call notification ───────────────────────────────────────

  Future<void> showIncomingCall({
    required String sessionId,
    required String callerUid,
    required String callerName,
    required String callerLang,
    required String receiverLang,
  }) async {
    await init();

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
      fullScreenIntent:   true,   // shows over lock screen
      autoCancel:         false,  // stays until user acts
      ongoing:            true,   // cannot be swiped away
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