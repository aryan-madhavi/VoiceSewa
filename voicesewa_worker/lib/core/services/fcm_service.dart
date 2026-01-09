import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

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

  // Listen to token refresh
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      print('✅ Subscribed to topic: $topic');
    } catch (e) {
      print('❌ Error subscribing to topic $topic: $e');
    }
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      print('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      print('❌ Error unsubscribing from topic $topic: $e');
    }
  }

  // Check current permission status
  Future<bool> isNotificationPermissionGranted() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  // NEW: Setup foreground message handler
  void setupForegroundMessageHandler(BuildContext context) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📬 Foreground notification received');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      print('Data: ${message.data}');

      // Show dialog when app is open
      if (message.notification != null) {
        _showForegroundNotificationDialog(context, message);
      }
    });
  }

  // NEW: Show notification dialog when app is in foreground
  void _showForegroundNotificationDialog(
    BuildContext context,
    RemoteMessage message,
  ) {
    final notification = message.notification!;
    final data = message.data;
    final type = data['type'] ?? 'unknown';

    // Get action button text based on notification type
    String actionText = _getActionText(type);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            _getNotificationIcon(type),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                notification.title ?? 'Notification',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
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
            child: const Text('Later', style: TextStyle(color: Colors.grey)),
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

  // Get icon based on notification type
  Widget _getNotificationIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'new_job':
        icon = Icons.work;
        color = Colors.blue;
        break;
      case 'job_update':
        icon = Icons.update;
        color = Colors.orange;
        break;
      case 'booking':
        icon = Icons.calendar_today;
        color = Colors.green;
        break;
      case 'earning':
        icon = Icons.attach_money;
        color = Colors.green;
        break;
      case 'profile':
        icon = Icons.person;
        color = Colors.purple;
        break;
      default:
        icon = Icons.notifications;
        color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  // Setup notification tap handlers (background/terminated)
  Future<void> setupNotificationHandlers() async {
    // Handle notification tap when app is TERMINATED (completely closed)
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      print('🚀 App opened from TERMINATED state via notification');
      _handleNotificationTap(initialMessage);
    }

    // Handle notification tap when app is in BACKGROUND
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🔔 App opened from BACKGROUND state via notification');
      _handleNotificationTap(message);
    });
  }

  // Handle notification tap and navigate
  void _handleNotificationTap(RemoteMessage message) {
    print('📱 Notification tapped!');
    print('Data: ${message.data}');

    // Store the navigation data to be handled by app_gate.dart
    if (message.data.isNotEmpty) {
      _pendingNavigation = message.data;
    }
  }

  // Store pending navigation data
  Map<String, dynamic>? _pendingNavigation;

  // Get and clear pending navigation
  Map<String, dynamic>? getPendingNavigation() {
    final data = _pendingNavigation;
    _pendingNavigation = null;
    return data;
  }
}

// Provider for FCM Service
final fcmServiceProvider = Provider<FCMService>((ref) => FCMService());

// Provider for FCM token
final fcmTokenProvider = FutureProvider<String?>((ref) async {
  final fcmService = ref.watch(fcmServiceProvider);
  return await fcmService.getToken();
});
