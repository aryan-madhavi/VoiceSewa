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

    print('🔔 Setting up FCM...');

    // Setup foreground notification handler (shows dialog when app is open)
    fcmService.setupForegroundMessageHandler(context);

    // Setup notification tap handlers (background/terminated)
    await fcmService.setupNotificationHandlers();

    // Get and print FCM token
    final token = await fcmService.getToken();

    if (token != null) {
      print('📱 FCM Token obtained successfully');
      // TODO: Send token to your backend here

      // Subscribe to topics
      print('📢 Subscribing to topics...');
      await fcmService.subscribeToTopic('workers');
      await fcmService.subscribeToTopic('all_users');
      print('✅ Topic subscriptions complete');
    } else {
      print('⚠️ Failed to get FCM token');
    }

    // Listen to token refresh
    fcmService.onTokenRefresh.listen((newToken) {
      print('=====================================');
      print('🔄 FCM Token Refreshed');
      print('New Token: $newToken');
      print('=====================================');
      // TODO: Update token in your backend
    });

    print('✅ FCM setup complete');

    // Check for pending navigation from notification tap
    _checkPendingNavigation();
  }

  // Check and handle pending navigation
  void _checkPendingNavigation() {
    final fcmService = ref.read(fcmServiceProvider);
    final navigationData = fcmService.getPendingNavigation();

    if (navigationData != null && mounted) {
      print('🧭 Handling pending navigation: $navigationData');
      _handleNavigation(navigationData);
    }
  }

  // Handle navigation based on notification data
  void _handleNavigation(Map<String, dynamic> data) {
    // Wait a bit for the app to fully load
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      final type = data['type'];
      print('🎯 Navigating to: $type');

      switch (type) {
        case 'new_job':
          // Navigate to jobs page
          final jobId = data['jobId'];
          print('📋 Opening job: $jobId');
          // TODO: Replace with your actual navigation
          // Example: Navigator.pushNamed(context, '/job-details', arguments: jobId);
          break;

        case 'job_update':
          // Navigate to specific job details
          final jobId = data['jobId'];
          print('🔄 Opening job update: $jobId');
          // TODO: Replace with your actual navigation
          // Example: Navigator.pushNamed(context, '/job-details', arguments: jobId);
          break;

        case 'booking':
          // Navigate to bookings page
          final bookingId = data['bookingId'];
          print('📅 Opening booking: $bookingId');
          // TODO: Replace with your actual navigation
          // Example: Navigator.pushNamed(context, '/booking-details', arguments: bookingId);
          break;

        case 'earning':
          // Navigate to earnings page
          print('💰 Opening earnings page');
          // TODO: Replace with your actual navigation
          // Example: Navigator.pushNamed(context, '/earnings');
          break;

        case 'profile':
          // Navigate to profile page
          print('👤 Opening profile page');
          // TODO: Replace with your actual navigation
          // Example: Navigator.pushNamed(context, '/profile');
          break;

        default:
          print('⚠️ Unknown notification type: $type');
        // Do nothing or show home screen
      }
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

        // Only check profile for NEW users
        if (sessionState.isNewUser) {
          print('🆕 New user detected - checking profile completion');

          final profileCompletion = ref.watch(
            profileCompletionProvider(userId),
          );

          return profileCompletion.when(
            data: (isProfileComplete) {
              print('📊 Profile complete: $isProfileComplete');

              if (!isProfileComplete) {
                print('📝 Showing profile form for new user');
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
        } else {
          // EXISTING USER: Skip profile check, go directly to home
          print('👤 Existing user - going directly to home');
          return const RootScaffold();
        }

      case SessionStatus.loggedOut:
        return authScreen == AuthScreen.login
            ? const LoginScreen()
            : const SignupScreen();
    }
  }
}
