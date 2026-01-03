import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/features/auth/presentation/login_screen.dart';
import 'package:voicesewa_client/features/auth/providers/session_provider.dart';
import 'package:voicesewa_client/app/widgets/logged_in_handler.dart';

/// Main application gate that routes users based on authentication state
///
/// This is the root-level router that determines what the user sees:
/// - Loading: Checking session state
/// - LoggedIn: Initialize user workspace and check profile
/// - LoggedOut: Show authentication screen
class AppGate extends ConsumerWidget {
  const AppGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionStatus = ref.watch(sessionNotifierProvider);

    switch (sessionStatus) {
      case SessionStatus.loading:
        return _buildLoadingScreen('Checking session...');

      case SessionStatus.loggedIn:
        // User is authenticated - handle initialization and profile check
        return const LoggedInHandler();

      case SessionStatus.loggedOut:
        return const AuthScreen();
    }
  }

  Widget _buildLoadingScreen(String message) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }
}
