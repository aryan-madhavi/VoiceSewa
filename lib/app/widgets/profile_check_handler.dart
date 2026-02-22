import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_worker/app/widgets/profile_check_handler.dart';
import 'package:voicesewa_worker/core/services/fcm_service.dart';
import 'package:voicesewa_worker/core/widgets/layout/root_scaffold.dart';
import 'package:voicesewa_worker/features/auth/presentation/login_screen.dart';
import 'package:voicesewa_worker/features/auth/providers/auth_provider.dart';
import 'package:voicesewa_worker/features/auth/providers/profile_form_provider.dart';
import 'package:voicesewa_worker/features/profile/presentation/worker_profile_form_page.dart';
import 'package:voicesewa_worker/features/profile/providers/worker_profile_provider.dart';

/// Determines whether to show profile setup or the main app.
///
/// Decision logic (mirrors client app):
///   1. Profile just completed this session → Main App
///   2. User just registered this session  → Profile Setup
///   3. Has profile doc in Firestore       → Main App
///   4. No profile doc in Firestore        → Profile Setup
class ProfileCheckHandler extends ConsumerWidget {
  const ProfileCheckHandler({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    // Safety — should never be null here
    if (firebaseUser == null) {
      print('⚠️ No Firebase user in ProfileCheckHandler');
      return const LoginScreen();
    }

    final isNewRegistration = ref.watch(isNewRegistrationProvider);
    final isProfileComplete = ref.watch(profileCompletionProvider);
    final hasProfileAsync = ref.watch(userHasProfileProvider(firebaseUser.uid));

    print('📊 ProfileCheckHandler:');
    print('   uid            : ${firebaseUser.uid}');
    print('   isNewReg       : $isNewRegistration');
    print('   isProfileDone  : $isProfileComplete');

    // PRIORITY 1 — Profile was just filled in → go to main app
    if (isProfileComplete) {
      print('✅ Profile just completed → Main App');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(profileCompletionProvider.notifier).reset();
        ref.read(isNewRegistrationProvider.notifier).reset();
        ref.read(fcmServiceProvider).requestPermissionAndSave(firebaseUser.uid);
      });
      return const RootScaffold();
    }

    // PRIORITY 2 — Fresh registration → show profile setup
    if (isNewRegistration) {
      print('🆕 New registration → Profile Setup');
      return const WorkerProfileFormPage();
    }

    // PRIORITY 3 — Check Firestore (uses offline cache when offline)
    return hasProfileAsync.when(
      data: (hasProfile) {
        if (hasProfile) {
          print('✅ Firestore profile found → Main App');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref
                .read(fcmServiceProvider)
                .requestPermissionAndSave(firebaseUser.uid);
          });
          return const RootScaffold();
        }
        print('📝 No Firestore profile → Profile Setup');
        return const WorkerProfileFormPage();
      },
      loading: () => const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading profile...'),
            ],
          ),
        ),
      ),
      error: (error, _) {
        print('❌ Error checking Firestore profile: $error');
        return const WorkerProfileFormPage();
      },
    );
  }
}
