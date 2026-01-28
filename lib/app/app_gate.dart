import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/features/auth/presentation/login_screen.dart';
import 'package:voicesewa_client/features/auth/providers/auth_provider.dart';
import 'package:voicesewa_client/app/widgets/profile_check_handler.dart';

/// Main application gate that routes users based on Firebase authentication state
///
/// This is the root-level router that determines what the user sees:
/// - Loading: Checking Firebase auth state
/// - LoggedIn: Check if profile exists, then route accordingly
/// - LoggedOut: Show authentication screen
///
/// SIMPLIFIED: No database initialization needed since we use pure Firebase
class AppGate extends ConsumerWidget {
  const AppGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionStatus = ref.watch(sessionStatusProvider);

    switch (sessionStatus) {
      case SessionStatus.loading:
        return _buildLoadingScreen('Checking authentication...');

      case SessionStatus.loggedIn:
        // User is authenticated - check profile and route
        // No database initialization needed - pure Firebase approach
        return const ProfileCheckHandler();

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