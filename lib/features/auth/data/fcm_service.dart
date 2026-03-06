// lib/features/auth/data/fcm_service.dart
//
// Manages the FCM lifecycle:
//   1. Save FCM token to Firestore users/{uid}/fcmToken on init and rotation
//   2. Foreground FCM messages → show local notification via NotificationService
//   3. Background tap (onMessageOpenedApp) → call onCallNotificationTap
//   4. Terminated tap (getInitialMessage) → call onCallNotificationTap
//
// The local notification tap (banner tap while app is open or in shade) is
// handled entirely by NotificationService via onDidReceiveNotificationResponse.
// FcmService only handles raw FCM message taps (background/terminated).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants.dart';
import '../../translate_call/data/notification_service.dart';

class FcmService {
  FcmService({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// Call once from CallTranslateApp after ProviderScope is ready.
  /// [onCallNotificationTap] is invoked with the sessionId whenever the user
  /// opens the app by tapping an FCM notification (background or terminated).
  Future<void> init({
    required void Function(String sessionId) onCallNotificationTap,
  }) async {
    // 1. Save token to Firestore
    await saveToken();

    // 2. Re-save whenever FCM rotates the token
    FirebaseMessaging.instance.onTokenRefresh.listen((_) => saveToken());

    // 3. Foreground FCM message — show local notification
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 4. Background tap — app was in background, user tapped FCM notification
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('[FCM] onMessageOpenedApp tap');
      _routeTap(message, onCallNotificationTap);
    });

    // 5. Terminated tap — app was closed, user tapped FCM notification
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      debugPrint('[FCM] getInitialMessage tap');
      _routeTap(initial, onCallNotificationTap);
    }
  }

  // ── Token ─────────────────────────────────────────────────────────────────

  Future<String?> getToken() => FirebaseMessaging.instance.getToken();

  Future<void> saveToken() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .set({'fcmToken': token}, SetOptions(merge: true));

    debugPrint('[FCM] token saved uid=${user.uid}');
  }

  // ── Foreground message ────────────────────────────────────────────────────

  void _handleForegroundMessage(RemoteMessage message) {
    final type = message.data['type'] as String?;
    if (type != AppConstants.fcmTypeIncomingCall) return;

    debugPrint('[FCM] foreground incoming call message');

    // FCM does not show a notification when app is foregrounded.
    // Show one manually via flutter_local_notifications so the user sees the
    // banner and can tap it — NotificationService handles the tap.
    NotificationService.instance.showIncomingCall(
      sessionId:    message.data['sessionId']    ?? '',
      callerUid:    message.data['callerUid']    ?? '',
      callerName:   message.data['callerName']   ?? 'Unknown',
      callerLang:   message.data['callerLang']   ?? 'hi-IN',
      receiverLang: message.data['receiverLang'] ?? 'en-IN',
    );
  }

  // ── FCM tap routing ───────────────────────────────────────────────────────

  void _routeTap(
    RemoteMessage message,
    void Function(String sessionId) onTap,
  ) {
    final type      = message.data['type'] as String?;
    final sessionId = message.data['sessionId'] as String?;

    if (type != AppConstants.fcmTypeIncomingCall) return;
    if (sessionId == null || sessionId.isEmpty) return;

    onTap(sessionId);
  }
}