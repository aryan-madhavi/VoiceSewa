import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Get FCM token
  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      print('FCM Token: $token');
      return token;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  // Listen to token refresh
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  // Setup foreground message handling
  void setupForegroundMessageHandler(BuildContext context) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message received');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      print('Data: ${message.data}');

      // Show in-app notification or handle data
      if (message.notification != null) {
        _showNotificationDialog(context, message);
      }

      // Handle data payload
      _handleNotificationData(message.data);
    });
  }

  // Handle notification when app is opened from background/terminated state
  Future<void> setupNotificationInteraction() async {
    // Handle when app is opened from terminated state
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationData(initialMessage.data);
    }

    // Handle when app is opened from background state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification opened from background');
      _handleNotificationData(message.data);
    });
  }

  // Show notification dialog when app is in foreground
  void _showNotificationDialog(BuildContext context, RemoteMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(message.notification?.title ?? 'Notification'),
        content: Text(message.notification?.body ?? ''),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleNotificationData(message.data);
            },
            child: const Text('Open'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Handle notification data payload
  void _handleNotificationData(Map<String, dynamic> data) {
    print('Handling notification data: $data');

    // Route based on notification type
    if (data.containsKey('type')) {
      switch (data['type']) {
        case 'new_job':
          // Navigate to jobs page
          print('New job notification');
          break;
        case 'job_update':
          // Navigate to specific job
          print('Job update notification');
          break;
        case 'earning':
          // Navigate to earnings page
          print('Earning notification');
          break;
        default:
          print('Unknown notification type');
      }
    }
  }

  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic: $e');
    }
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Error unsubscribing from topic: $e');
    }
  }
}

// Provider for FCM Service
final fcmServiceProvider = Provider<FCMService>((ref) => FCMService());

// Provider for FCM token
final fcmTokenProvider = FutureProvider<String?>((ref) async {
  final fcmService = ref.watch(fcmServiceProvider);
  return await fcmService.getToken();
});
