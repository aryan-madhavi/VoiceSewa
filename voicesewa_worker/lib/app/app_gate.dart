import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:voicesewa_worker/core/database/app_database.dart';
import 'package:voicesewa_worker/core/services/fcm_service.dart';
import 'package:voicesewa_worker/core/widgets/layout/root_scaffold.dart';
import 'package:voicesewa_worker/features/auth/presentation/login_screen.dart';
import 'package:voicesewa_worker/features/auth/presentation/signup_screen.dart';
import 'package:voicesewa_worker/core/providers/session_provider.dart';
import 'package:voicesewa_worker/features/auth/provider/auth_screen_provider.dart';
import 'package:voicesewa_worker/features/profile/presentation/worker_profile_form_page.dart';
import 'package:voicesewa_worker/features/profile/providers/worker_profile_provider.dart';

class AppGate extends ConsumerStatefulWidget {
  const AppGate({super.key});

  @override
  ConsumerState<AppGate> createState() => _AppGateState();
}

class _AppGateState extends ConsumerState<AppGate> {
  @override
  void initState() {
    super.initState();

    // Setup FCM after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupFCM();
    });
  }

  Future<void> _setupFCM() async {
    final fcmService = ref.read(fcmServiceProvider);

    // Setup foreground message handler
    fcmService.setupForegroundMessageHandler(context);

    // Setup notification interaction
    await fcmService.setupNotificationInteraction();

    // Get and store FCM token
    final token = await fcmService.getToken();
    if (token != null) {
      // TODO: Send token to your backend
      print('FCM Token ready: $token');

      // Subscribe to topics based on user role
      await fcmService.subscribeToTopic('workers');
      await fcmService.subscribeToTopic('all_users');
    }

    // Listen to token refresh
    fcmService.onTokenRefresh.listen((newToken) {
      print('FCM Token refreshed: $newToken');
      // TODO: Update token in your backend
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionNotifierProvider);
    final authScreen = ref.watch(authScreenProvider);

    switch (sessionState.status) {
      case SessionStatus.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));

      case SessionStatus.loggedIn:
        String? userId = WorkerDatabase.currentUserId;

        if (userId == null || userId.isEmpty) {
          userId = FirebaseAuth.instance.currentUser?.email;

          if (userId != null) {
            WorkerDatabase.instanceForUser(userId);
          }
        }

        if (userId == null || userId.isEmpty) {
          return const Scaffold(
            body: Center(
              child: Text("Error: User ID not found. Please restart."),
            ),
          );
        }

        final profileCompletion = ref.watch(profileCompletionProvider(userId));

        return profileCompletion.when(
          data: (isProfileComplete) {
            print(
              '📊 Profile complete: $isProfileComplete, isNewUser: ${sessionState.isNewUser}',
            );

            if (!isProfileComplete) {
              print('🆕 Showing profile form (profile incomplete)');
              return const WorkerProfileFormPage();
            }

            print('✅ Profile complete, navigating to home');
            return const RootScaffold();
          },
          loading: () {
            print('⏳ Loading profile completion status...');
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          },
          error: (error, stack) {
            print('❌ Error checking profile: $error');
            return const WorkerProfileFormPage();
          },
        );

      case SessionStatus.loggedOut:
        return authScreen == AuthScreen.login
            ? const LoginScreen()
            : const SignupScreen();
    }
  }
}
