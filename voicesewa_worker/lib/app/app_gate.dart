import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_worker/core/widgets/layout/root_scaffold.dart';
import 'package:voicesewa_worker/features/auth/presentation/login_screen.dart';
import 'package:voicesewa_worker/features/auth/presentation/signup_screen.dart';
import 'package:voicesewa_worker/core/providers/session_provider.dart';
import 'package:voicesewa_worker/features/auth/provider/auth_screen_provider.dart';
import 'package:voicesewa_worker/features/sync/presentation/sync_initializer.dart';

class AppGate extends ConsumerWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(sessionNotifierProvider);
    final authScreen = ref.watch(authScreenProvider);

    switch (sessionState.status) {
      case SessionStatus.loading:
        return const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Loading...',
                  style: TextStyle(fontSize: 16, color: Color(0xFF757575)),
                ),
              ],
            ),
          ),
        );

      case SessionStatus.loggedIn:
        return const SyncInitializer(child: const RootScaffold());

      case SessionStatus.loggedOut:
        // Switch between login and signup based on provider
        return authScreen == AuthScreen.login
            ? const LoginScreen()
            : const SignupScreen();
    }
  }
}
