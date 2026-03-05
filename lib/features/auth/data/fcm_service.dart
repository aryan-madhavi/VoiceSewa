// lib/features/auth/data/fcm_service.dart
//
// Manages the complete FCM lifecycle for the call feature:
//
//   1. Token  — get the device FCM token, save it to Firestore under
//               users/{uid}/fcmToken so the Cloud Function can read it
//               when the caller creates a call doc.
//
//   2. Token refresh — re-save whenever FCM rotates the token.
//
//   3. Foreground messages — when the app is open, FCM data messages
//               don't show a notification automatically; we call
//               NotificationService.showIncomingCall() ourselves.
//
//   4. Notification tap — when the user taps the heads-up banner
//               (app backgrounded or terminated), we get a callback
//               and navigate to the incoming call screen.
//
// Sending the notification is NOT done here — a Cloud Function
// (functions/index.js) listens for new call docs and sends FCM
// using the Admin SDK server-side.

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

  // ── init ──────────────────────────────────────────────────────────────────

  Future<void> init({
    required void Function(String sessionId) onCallNotificationTap,
  }) async {
    // Save current token to Firestore
    await saveToken();

    // Re-save on rotation
    FirebaseMessaging.instance.onTokenRefresh.listen((_) => saveToken());

    // Foreground: FCM arrives while app is open
    FirebaseMessaging.onMessage.listen(_handleDataMessage);

    // Background tap: user tapped notification, app was backgrounded
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleTap(message, onCallNotificationTap);
    });

    // Terminated tap: user tapped notification, app was closed
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      _handleTap(initial, onCallNotificationTap);
    }
  }

  // ── Token management ──────────────────────────────────────────────────────

  Future<String?> getToken() => FirebaseMessaging.instance.getToken();

  /// Saves the current FCM token to users/{uid} in Firestore.
  /// Called on init and whenever the token rotates.
  Future<void> saveToken() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .set({'fcmToken': token}, SetOptions(merge: true));

    debugPrint('[FCM] token saved for uid=${user.uid}');
  }

  // ── Message handlers ──────────────────────────────────────────────────────

  void _handleDataMessage(RemoteMessage message) {
    final type = message.data['type'] as String?;
    if (type != AppConstants.fcmTypeIncomingCall) return;

    NotificationService.instance.showIncomingCall(
      sessionId:    message.data['sessionId']    ?? '',
      callerUid:    message.data['callerUid']    ?? '',
      callerName:   message.data['callerName']   ?? 'Unknown',
      callerLang:   message.data['callerLang']   ?? 'hi-IN',
      receiverLang: message.data['receiverLang'] ?? 'en-IN',
    );
  }

  void _handleTap(
    RemoteMessage message,
    void Function(String sessionId) onTap,
  ) {
    final sessionId = message.data['sessionId'] as String?;
    if (sessionId != null && sessionId.isNotEmpty) {
      onTap(sessionId);
    }
  }
}