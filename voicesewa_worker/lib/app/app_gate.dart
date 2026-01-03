import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:voicesewa_worker/core/database/app_database.dart';
import 'package:voicesewa_worker/core/widgets/layout/root_scaffold.dart';
import 'package:voicesewa_worker/features/auth/presentation/login_screen.dart';
import 'package:voicesewa_worker/features/auth/presentation/signup_screen.dart';
import 'package:voicesewa_worker/core/providers/session_provider.dart';
import 'package:voicesewa_worker/features/auth/provider/auth_screen_provider.dart';
import 'package:voicesewa_worker/features/profile/presentation/worker_profile_form_page.dart';
import 'package:voicesewa_worker/features/profile/providers/worker_profile_provider.dart';
import 'package:voicesewa_worker/features/sync/presentation/sync_initializer.dart';

class AppGate extends ConsumerWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(sessionNotifierProvider);
    final authScreen = ref.watch(authScreenProvider);

    switch (sessionState.status) {
      case SessionStatus.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));

      case SessionStatus.loggedIn:
        // 1. Get user ID
        String? userId = WorkerDatabase.currentUserId;

        // 2. Fallback: If Local DB isn't ready, use Firebase Auth ID
        if (userId == null || userId.isEmpty) {
          userId = FirebaseAuth.instance.currentUser?.email;

          // If we found it in Firebase but not Local DB, init Local DB now
          if (userId != null) {
            WorkerDatabase.instanceForUser(userId);
          }
        }

        // 3. If STILL null, show error
        if (userId == null || userId.isEmpty) {
          return const Scaffold(
            body: Center(
              child: Text("Error: User ID not found. Please restart."),
            ),
          );
        }

        // 4. Check if profile is complete
        final profileCompletion = ref.watch(profileCompletionProvider(userId));

        return profileCompletion.when(
          data: (isProfileComplete) {
            print(
              '📊 Profile complete: $isProfileComplete, isNewUser: ${sessionState.isNewUser}',
            );

            // Show profile form if:
            // - Profile doesn't exist AND user just registered (isNewUser = true)
            // OR
            // - Profile doesn't exist (regardless of isNewUser, for safety)
            if (!isProfileComplete) {
              print('🆕 Showing profile form (profile incomplete)');
              return const WorkerProfileFormPage();
            }

            // Profile exists, go to home
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
            // On error, show profile form to be safe
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
