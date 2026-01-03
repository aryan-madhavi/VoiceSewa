import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/core/widgets/layout/root_scaffold.dart';
import 'package:voicesewa_client/features/auth/presentation/login_screen.dart';
import 'package:voicesewa_client/features/auth/presentation/profile_form_screen.dart';
import 'package:voicesewa_client/features/auth/providers/profile_form_provider.dart';
import 'package:voicesewa_client/features/sync/presentation/sync_initializer.dart';
import 'package:voicesewa_client/app/services/user_profile_checker.dart';

/// Determines whether to show profile setup or main app
///
/// Decision Logic (PRIORITY ORDER):
/// 1. If profile was just completed → Main App
/// 2. If profile exists in LOCAL database → Main App (PRIORITY!)
/// 3. If profile exists in Firestore → Main App
/// 4. If user is NEW and no profile anywhere → Profile Setup
/// 5. If user EXISTS but no profile anywhere → Profile Setup
///
/// Uses UserProfileChecker service for the actual checks.
class ProfileCheckHandler extends ConsumerWidget {
  const ProfileCheckHandler({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    // Watch profile completion status
    final isProfileComplete = ref.watch(profileCompletionProvider);

    // Safety check - should never happen
    if (firebaseUser == null) {
      print('⚠️ No Firebase user in ProfileCheckHandler - returning to auth');
      return const AuthScreen();
    }

    // If profile was just completed, go directly to main app
    if (isProfileComplete) {
      print('✅ Profile completed, navigating to main app');
      // Reset the completion flag
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(profileCompletionProvider.notifier).reset();
      });
      return const SyncInitializer(child: RootScaffold());
    }

    // Use FutureBuilder to check profile status
    return FutureBuilder<ProfileCheckResult>(
      future: UserProfileChecker.checkProfileStatus(firebaseUser),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        // Error state - default to profile setup for safety
        if (snapshot.hasError) {
          print('❌ Profile check error: ${snapshot.error}');
          return const ProfileSetupScreen();
        }

        // Success - route based on result
        final result = snapshot.data!;
        return _routeBasedOnProfileStatus(result);
      },
    );
  }

  /// Route user based on profile check result
  ///
  /// IMPORTANT: Local database takes priority!
  /// If local profile exists, user goes to main app regardless
  /// of Firebase Auth timestamps or Firestore status.
  Widget _routeBasedOnProfileStatus(ProfileCheckResult result) {
    print('📊 Profile Check Results:');
    print('   - Is new user: ${result.isNewUser}');
    print('   - Has LOCAL profile: ${result.hasLocalProfile}');
    // print('   - Has cloud profile: ${result.hasCloudProfile}');

    // PRIORITY CHECK: If local profile exists, go to main app!
    if (result.hasLocalProfile) {
      print('✅ Local profile exists → Main App');
      return const SyncInitializer(child: RootScaffold());
    }

    // If cloud profile exists (but not local), go to main app
    // The sync service will download the profile to local DB
    // if (result.hasCloudProfile) {
    //   print('✅ Cloud profile exists → Main App (will sync down)');
    //   return const SyncInitializer(child: RootScaffold());
    // }

    // No profile exists anywhere - need to create one
    if (result.isNewUser) {
      print('🆕 New user without profile → Profile Setup');
    } else {
      print('⚠️ Existing user without profile → Profile Setup');
    }

    return const ProfileSetupScreen();
  }

  Widget _buildLoadingScreen() {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Checking profile...'),
          ],
        ),
      ),
    );
  }
}
