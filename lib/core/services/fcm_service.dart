import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_worker/core/constants/color_constants.dart';
import 'package:voicesewa_worker/features/profile/data/repositories/worker_profile_repository.dart';

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final WorkerProfileRepository _profileRepo;

  FCMService(this._profileRepo);

  // Stream that emits notification data when user taps a notification
  final _notificationTapController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onNotificationTap =>
      _notificationTapController.stream;

  // Get FCM token
  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        print('=====================================');
        print('FCM Token: $token');
        print('=====================================');
      }
      return token;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  /// Request notification permission, fetch the FCM token, save it to
  /// Firestore under the worker's document, and listen for token rotations.
  Future<void> requestPermissionAndSave(String uid) async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      print('🔔 Notification permission: ${settings.authorizationStatus}');

      final granted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      if (!granted) {
        print('⚠️ Notification permission not granted — skipping token save');
        return;
      }

      final token = await _messaging.getToken();
      if (token != null) {
        await _profileRepo.updateFcmToken(uid, token);
        print('✅ FCM token saved for uid: $uid');
      }

      // Keep token fresh — FCM rotates tokens occasionally
      _messaging.onTokenRefresh.listen((newToken) async {
        print('🔄 FCM token refreshed — updating Firestore');
        await _profileRepo.updateFcmToken(uid, newToken);
      });
    } catch (e) {
      print('❌ FCM requestPermissionAndSave error: $e');
    }
  }

  /// Clear the FCM token from Firestore on logout so other users
  /// on the same device don't receive this worker's notifications.
  Future<void> clearToken(String uid) async {
    try {
      await _profileRepo.updateFcmToken(uid, '');
      await _messaging.deleteToken();
      print('🧹 FCM token cleared for uid: $uid');
    } catch (e) {
      print('❌ FCM clearToken error: $e');
    }
  }

  // Setup foreground message handler
  // Pass a GlobalKey<NavigatorState> so the dialog can always find a valid context
  void setupForegroundMessageHandler(GlobalKey<NavigatorState> navigatorKey) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📬 Foreground notification received');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      print('Data: ${message.data}');

      final context = navigatorKey.currentContext;
      if (message.notification != null && context != null) {
        _showForegroundNotificationDialog(context, message);
      }
    });
  }

  // Show notification dialog when app is in foreground
  void _showForegroundNotificationDialog(
    BuildContext context,
    RemoteMessage message,
  ) {
    final notification = message.notification!;
    final data = message.data;
    final type = data['type'] ?? 'unknown';

    // Get action button text based on notification type
    final String actionText = _getActionText(type);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          notification.title ?? 'Notification',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Text(
          notification.body ?? '',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              print('❌ User dismissed notification');
            },
            child: const Text(
              'Later',
              style: TextStyle(color: ColorConstants.unselectedGrey),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              print('✅ User tapped: $actionText');
              _handleNotificationTap(message);
            },
            child: Text(actionText),
          ),
        ],
      ),
    );
  }

  // Get action button text based on notification type
  String _getActionText(String type) {
    switch (type) {
      case 'new_job':
        return 'See Job';
      case 'job_update':
        return 'View Update';
      case 'booking':
        return 'View Booking';
      case 'earning':
        return 'View Earnings';
      case 'profile':
        return 'View Profile';
      default:
        return 'Open';
    }
  }

  // Setup notification tap handlers (background only)
  // Terminated state is handled in AppGate directly where context is available
  void setupNotificationHandlers() {
    // Handle notification tap when app is in BACKGROUND
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🔔 App opened from BACKGROUND state via notification');
      _handleNotificationTap(message);
    });
  }

  // Handle notification tap — emits to stream so AppGate can navigate
  void _handleNotificationTap(RemoteMessage message) {
    print('📱 Notification tapped!');
    print('Data: ${message.data}');

    if (message.data.isNotEmpty) {
      _notificationTapController.add(message.data);
    }
  }

  void dispose() {
    _notificationTapController.close();
  }
}

// Provider for FCM Service
final fcmServiceProvider = Provider<FCMService>((ref) {
  final profileRepo = WorkerProfileRepository();
  return FCMService(profileRepo);
});
