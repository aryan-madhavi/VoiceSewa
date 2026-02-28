import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ══════════════════════════════════════════════════════════════════════════════
// Background handler — must be a top-level function
// ══════════════════════════════════════════════════════════════════════════════

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔔 [CLIENT] Background message: ${message.notification?.title}');
}

// ══════════════════════════════════════════════════════════════════════════════
// FcmService
// ══════════════════════════════════════════════════════════════════════════════

class FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream that AppGate listens to in order to trigger navigation on tap
  final _notificationTapController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onNotificationTap =>
      _notificationTapController.stream;

  // ── Permission + token save ────────────────────────────────────────────────

  /// Request permission and save FCM token to clients/{uid}/fcm_token.
  /// Call once after profile is confirmed (login or profile setup).
  Future<void> requestPermissionAndSave(String uid) async {
    try {
      print('🔔 [CLIENT] Requesting FCM permission for uid: $uid');

      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        print('❌ [CLIENT] FCM permission denied');
        return;
      }

      final token = await _messaging.getToken();
      if (token == null) {
        print('⚠️ [CLIENT] FCM token is null');
        return;
      }

      await _firestore.collection('clients').doc(uid).update({
        'fcm_token': token,
      });

      print('✅ [CLIENT] FCM token saved for uid: $uid');

      // Refresh token whenever it rotates
      _messaging.onTokenRefresh.listen((newToken) async {
        print('🔄 [CLIENT] FCM token refreshed');
        await _firestore.collection('clients').doc(uid).update({
          'fcm_token': newToken,
        });
      });
    } catch (e) {
      print('❌ [CLIENT] Error in requestPermissionAndSave: $e');
    }
  }

  /// Clear FCM token from Firestore on logout.
  Future<void> clearToken(String uid) async {
    try {
      await _firestore.collection('clients').doc(uid).update({'fcm_token': ''});
      await _messaging.deleteToken();
      print('✅ [CLIENT] FCM token cleared for uid: $uid');
    } catch (e) {
      print('⚠️ [CLIENT] Error clearing FCM token: $e');
    }
  }

  // ── Foreground handler ─────────────────────────────────────────────────────

  /// Show an in-app AlertDialog when a notification arrives while app is open.
  /// The OS handles system banners automatically when app is background/terminated.
  void setupForegroundMessageHandler(GlobalKey<NavigatorState> navigatorKey) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📬 [CLIENT] Foreground message: ${message.notification?.title}');

      final context = navigatorKey.currentContext;
      if (message.notification != null && context != null) {
        _showForegroundNotificationDialog(context, message);
      }
    });
  }

  void _showForegroundNotificationDialog(
    BuildContext context,
    RemoteMessage message,
  ) {
    final notification = message.notification!;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.notifications, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                notification.title ?? 'Notification',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(notification.body ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Dismiss'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (message.data.isNotEmpty) {
                _notificationTapController.add(message.data);
              }
            },
            child: const Text('View'),
          ),
        ],
      ),
    );
  }

  // ── Background tap handler ─────────────────────────────────────────────────

  /// Wire up background tap stream. Call once from AppGate.initState.
  void setupNotificationHandlers() {
    // App was in BACKGROUND and user tapped the notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📱 [CLIENT] Notification tapped from background');
      if (message.data.isNotEmpty) {
        _notificationTapController.add(message.data);
      }
    });
  }

  // ── Cleanup ────────────────────────────────────────────────────────────────

  void dispose() {
    _notificationTapController.close();
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Riverpod provider
// ══════════════════════════════════════════════════════════════════════════════

final fcmServiceProvider = Provider<FcmService>((ref) {
  final service = FcmService();
  ref.onDispose(service.dispose);
  return service;
});
