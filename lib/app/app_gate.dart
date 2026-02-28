import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/app/notification_router.dart';
import 'package:voicesewa_client/app/widgets/profile_check_handler.dart';
import 'package:voicesewa_client/features/auth/presentation/login_screen.dart';
import 'package:voicesewa_client/features/auth/providers/auth_provider.dart';
import 'package:voicesewa_client/features/auth/services/fcm_service.dart';

class AppGate extends ConsumerStatefulWidget {
  const AppGate({Key? key}) : super(key: key);

  @override
  ConsumerState<AppGate> createState() => _AppGateState();
}

class _AppGateState extends ConsumerState<AppGate> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<Map<String, dynamic>>? _notifSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setupFCM());
  }

  Future<void> _setupFCM() async {
    print('🔔 [CLIENT] FCM setup in AppGate');
    final fcmService = ref.read(fcmServiceProvider);

    // Foreground notifications — shows AlertDialog + system heads-up banner
    fcmService.setupForegroundMessageHandler(_navigatorKey);

    // Background tap handler — emits to onNotificationTap stream
    fcmService.setupNotificationHandlers();

    // Listen to tap stream and route to correct screen
    _notifSubscription = fcmService.onNotificationTap.listen((data) {
      if (mounted) NotificationRouter.navigate(context, ref, data);
    });

    // Terminated state — app cold-started via notification tap
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null && mounted) {
      print('🚀 [CLIENT] App opened from TERMINATED state via notification');
      NotificationRouter.navigate(context, ref, initialMessage.data);
    }
  }

  @override
  void dispose() {
    _notifSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionStatus = ref.watch(sessionStatusProvider);

    switch (sessionStatus) {
      case SessionStatus.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));

      case SessionStatus.loggedIn:
        return const ProfileCheckHandler();

      case SessionStatus.loggedOut:
        return const AuthScreen();
    }
  }
}
