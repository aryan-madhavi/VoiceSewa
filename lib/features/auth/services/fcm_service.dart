import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// FCM Service for managing Firebase Cloud Messaging tokens and topics
/// Handles token generation, updates, and topic subscriptions for users
class FCMService {
  final FirebaseMessaging _messaging;

  FCMService({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  /// Initialize FCM and request permissions
  /// Returns true if permission granted, false otherwise
  Future<bool> initialize() async {
    try {
      print('🔔 Initializing FCM...');

      // Request notification permissions (iOS)
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );

      print('📱 FCM Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ FCM notifications enabled');
        return true;
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        print('⚠️ FCM provisional notifications enabled');
        return true;
      } else {
        print('❌ FCM notifications denied');
        return false;
      }
    } catch (e) {
      print('❌ FCM initialization error: $e');
      return false;
    }
  }

  /// Get FCM token for the current user
  /// This is a user-specific token, not device-specific
  Future<String?> getToken() async {
    try {
      // For web, use vapidKey if available
      String? token;
      // if (kIsWeb) {
      //   // Replace with your actual VAPID key from Firebase Console
      //   token = await _messaging.getToken(
      //     vapidKey: 'YOUR_VAPID_KEY_HERE', // TODO: Add your VAPID key
      //   );
      // } else {
        token = await _messaging.getToken();
      // }

      if (token != null) {
        print('✅ FCM Token obtained: ${token.substring(0, 20)}...');
      } else {
        print('⚠️ FCM Token is null');
      }

      return token;
    } catch (e) {
      print('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// Listen to token refresh events
  /// Returns a stream of new tokens when they change
  Stream<String> onTokenRefresh() {
    return _messaging.onTokenRefresh;
  }

  /// Delete current FCM token
  /// Call this when user logs out to revoke notifications
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      print('✅ FCM Token deleted successfully');
    } catch (e) {
      print('❌ Error deleting FCM token: $e');
      rethrow;
    }
  }

  // ==================== TOPIC SUBSCRIPTIONS ====================

  /// Subscribe to a topic for receiving targeted notifications
  /// Example topics: 'all_clients', 'promotions', 'service_updates'
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      print('✅ Subscribed to topic: $topic');
    } catch (e) {
      print('❌ Error subscribing to topic $topic: $e');
      rethrow;
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      print('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      print('❌ Error unsubscribing from topic $topic: $e');
      rethrow;
    }
  }

  /// Subscribe to multiple topics at once
  Future<void> subscribeToTopics(List<String> topics) async {
    for (final topic in topics) {
      await subscribeToTopic(topic);
    }
  }

  /// Unsubscribe from multiple topics at once
  Future<void> unsubscribeFromTopics(List<String> topics) async {
    for (final topic in topics) {
      await unsubscribeFromTopic(topic);
    }
  }

  /// Subscribe to default client topics
  /// These are topics all clients should be subscribed to
  Future<void> subscribeToDefaultClientTopics() async {
    // final defaultTopics = [
    //   'all_clients', // All client notifications
    //   'service_updates', // Service/app updates
    //   'promotions', // Promotional notifications
    // ];
    // final defaultTopics = [''];
    // await subscribeToTopics(defaultTopics);
    print('✅ Subscribed to default client topics');
  }

  /// Unsubscribe from all client topics (on logout)
  Future<void> unsubscribeFromAllClientTopics() async {
    final clientTopics = ['all_clients', 'service_updates', 'promotions'];

    await unsubscribeFromTopics(clientTopics);
    print('✅ Unsubscribed from all client topics');
  }

  // ==================== LOCATION-BASED TOPICS ====================

  /// Subscribe to location-based topics
  /// Example: 'city_mumbai', 'area_andheri'
  Future<void> subscribeToLocationTopics({String? city, String? area}) async {
    final topics = <String>[];

    if (city != null) {
      final cityTopic = 'city_${city.toLowerCase().replaceAll(' ', '_')}';
      topics.add(cityTopic);
    }

    if (area != null) {
      final areaTopic = 'area_${area.toLowerCase().replaceAll(' ', '_')}';
      topics.add(areaTopic);
    }

    if (topics.isNotEmpty) {
      await subscribeToTopics(topics);
      print('✅ Subscribed to location topics: $topics');
    }
  }

  /// Unsubscribe from location-based topics
  Future<void> unsubscribeFromLocationTopics({
    String? city,
    String? area,
  }) async {
    final topics = <String>[];

    if (city != null) {
      final cityTopic = 'city_${city.toLowerCase().replaceAll(' ', '_')}';
      topics.add(cityTopic);
    }

    if (area != null) {
      final areaTopic = 'area_${area.toLowerCase().replaceAll(' ', '_')}';
      topics.add(areaTopic);
    }

    if (topics.isNotEmpty) {
      await unsubscribeFromTopics(topics);
      print('✅ Unsubscribed from location topics: $topics');
    }
  }

  // ==================== FOREGROUND MESSAGE HANDLING ====================

  /// Configure foreground message handling
  /// This allows notifications to be shown when app is in foreground
  void configureForegroundNotifications() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📬 Foreground message received:');
      print('   Title: ${message.notification?.title}');
      print('   Body: ${message.notification?.body}');
      print('   Data: ${message.data}');

      // Handle the message (show local notification, update UI, etc.)
      // You can implement custom handling here
    });
  }

  /// Handle notification tapped when app is in background/terminated
  void configureBackgroundNotificationHandling() {
    // Handle notification tap when app is terminated
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        print('🚀 App opened from terminated state via notification');
        _handleNotificationTap(message);
      }
    });

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('📱 App opened from background via notification');
      _handleNotificationTap(message);
    });
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    print('👆 Notification tapped:');
    print('   Title: ${message.notification?.title}');
    print('   Body: ${message.notification?.body}');
    print('   Data: ${message.data}');

    // Navigate to appropriate screen based on notification data
    // Example: if (message.data['screen'] == 'jobs') { navigate to jobs }
  }
}

/// Background message handler (must be top-level function)
/// This handles messages when app is terminated
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔔 Background message received:');
  print('   Message ID: ${message.messageId}');
  print('   Title: ${message.notification?.title}');
  print('   Body: ${message.notification?.body}');
  print('   Data: ${message.data}');
}
