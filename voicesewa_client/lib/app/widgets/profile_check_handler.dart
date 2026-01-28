import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/core/widgets/layout/root_scaffold.dart';
import 'package:voicesewa_client/features/auth/presentation/login_screen.dart';
import 'package:voicesewa_client/features/auth/presentation/profile_form_screen.dart';
import 'package:voicesewa_client/features/auth/providers/profile_form_provider.dart';
import 'package:voicesewa_client/features/sync/presentation/sync_initializer.dart';

/// Determines whether to show profile setup or main app
///
/// Decision Logic:
/// 1. If profile was just completed → Main App
/// 2. If user just registered → Profile Setup Screen
/// 3. If user logged in → Main App
///
/// NO database or Firestore checks are performed.
/// Routing is based purely on registration vs login status.
class ProfileCheckHandler extends ConsumerWidget {
  const ProfileCheckHandler({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    // Watch registration status (set by login/register forms)
    final isNewRegistration = ref.watch(isNewRegistrationProvider);

    // Watch profile completion status (set by profile form)
    final isProfileComplete = ref.watch(profileCompletionProvider);

    // Safety check - should never happen
    if (firebaseUser == null) {
      print('⚠️ No Firebase user in ProfileCheckHandler - returning to auth');
      return const AuthScreen();
    }

    print('📊 Profile Check Status:');
    print('   - User: ${firebaseUser.email}');
    print('   - Is new registration: $isNewRegistration');
    print('   - Is profile complete: $isProfileComplete');

    // PRIORITY 1: If profile was just completed, go to main app
    if (isProfileComplete) {
      print('✅ Profile completed, navigating to main app');

      // Reset both flags
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(profileCompletionProvider.notifier).reset();
        ref.read(isNewRegistrationProvider.notifier).reset();
      });

      return const SyncInitializer(child: RootScaffold());
    }

    // PRIORITY 2: If user just registered, show profile setup
    if (isNewRegistration) {
      print('🆕 New registration detected → Profile Setup Screen');
      return const ProfileSetupScreen();
    }

    // PRIORITY 3: User logged in (not a new registration) → Main app
    print('✅ Existing user login → Main App');
    return const SyncInitializer(child: RootScaffold());
  }
}
