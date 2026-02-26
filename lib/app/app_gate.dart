import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_worker/app/notification_router.dart';
import 'package:voicesewa_worker/app/widgets/profile_check_handler.dart';
import 'package:voicesewa_worker/core/providers/session_provider.dart';
import 'package:voicesewa_worker/core/services/fcm_service.dart';
import 'package:voicesewa_worker/features/auth/presentation/login_screen.dart';
import 'package:voicesewa_worker/features/auth/presentation/signup_screen.dart';
import 'package:voicesewa_worker/features/auth/providers/auth_screen_provider.dart';

class AppGate extends ConsumerStatefulWidget {
  const AppGate({super.key});

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
    print('🔔 FCM setup in AppGate');
    final fcmService = ref.read(fcmServiceProvider);

    // Foreground notifications — uses navigatorKey to safely get context
    fcmService.setupForegroundMessageHandler(_navigatorKey);

    // Background tap handler
    fcmService.setupNotificationHandlers();

    // Listen to tap stream and navigate
    _notifSubscription = fcmService.onNotificationTap.listen((data) {
      NotificationRouter.navigate(context, ref, data);
    });

    // Terminated state — handle immediately with context
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null && mounted) {
      print('🚀 App opened from TERMINATED state via notification');
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
    // Now reads from stream-derived provider — no manual state, no race conditions.
    final sessionStatus = ref.watch(sessionStatusProvider);
    final authScreen = ref.watch(authScreenProvider);

    switch (sessionStatus) {
      case SessionStatus.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));

      case SessionStatus.loggedIn:
        return const ProfileCheckHandler();

      case SessionStatus.loggedOut:
        // ValueKeys ensure Flutter reuses the same widget instance,
        // so controllers/fields survive provider rebuilds.
        return authScreen == AuthScreen.login
            ? const LoginScreen(key: ValueKey('login'))
            : const SignupScreen(key: ValueKey('signup'));
    }
  }
}
