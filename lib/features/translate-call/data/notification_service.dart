// lib/features/translate_call/data/notification_service.dart
//
// Wraps flutter_local_notifications.
// Responsible for:
//   - Creating the Android "Incoming Calls" high-priority channel on init
//   - Showing a full-screen / heads-up incoming call notification
//   - Dismissing it after the user accepts or declines
//
// This is a plain singleton — no Riverpod needed here because it must
// also be accessible from the top-level FCM background handler in main.dart
// (which runs before ProviderScope exists).

import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../../core/constants.dart';

// ── Notification payload ──────────────────────────────────────────────────────
// Packed into every call notification so we can extract call details when
// the user taps the notification while the app is terminated.

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
        sessionId:   json['sessionId']   as String,
        callerUid:   json['callerUid']   as String,
        callerName:  json['callerName']  as String,
        callerLang:  json['callerLang']  as String,
        receiverLang: json['receiverLang'] as String,
      );

  Map<String, dynamic> toJson() => {
        'sessionId':   sessionId,
        'callerUid':   callerUid,
        'callerName':  callerName,
        'callerLang':  callerLang,
        'receiverLang': receiverLang,
      };

  String encode() => jsonEncode(toJson());

  static CallNotificationPayload decode(String raw) =>
      CallNotificationPayload.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
}

// ── Service ───────────────────────────────────────────────────────────────────

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialised = false;

  // ── Init — call once from main() and from the background FCM handler ───────

  Future<void> init() async {
    if (_initialised) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      // Permissions are requested separately via firebase_messaging
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    await _createCallChannel();
    _initialised = true;
  }

  Future<void> _createCallChannel() async {
    const channel = AndroidNotificationChannel(
      AppConstants.callChannelId,
      AppConstants.callChannelName,
      description: AppConstants.callChannelDesc,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // ── Show incoming call notification ───────────────────────────────────────
  // On Android 10+: full-screen intent (renders over the lock screen).
  // On older Android / iOS: heads-up banner.

  Future<void> showIncomingCall({
    required String sessionId,
    required String callerUid,
    required String callerName,
    required String callerLang,
    required String receiverLang,
  }) async {
    await init(); // safe to call multiple times

    final payload = CallNotificationPayload(
      sessionId:   sessionId,
      callerUid:   callerUid,
      callerName:  callerName,
      callerLang:  callerLang,
      receiverLang: receiverLang,
    );

    final androidDetails = AndroidNotificationDetails(
      AppConstants.callChannelId,
      AppConstants.callChannelName,
      channelDescription: AppConstants.callChannelDesc,
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.call,
      fullScreenIntent: true,  // shows over lock screen
      autoCancel: false,       // stays until user acts
      ongoing: true,           // cannot be swiped away
      ticker: 'Incoming call from $callerName',
      styleInformation: BigTextStyleInformation(
        callerName,
        summaryText: 'Auto-translation enabled',
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBanner: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    await _plugin.show(
      // Stable notification ID derived from sessionId so we can cancel it later
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