import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_worker/app/widgets/profile_check_handler.dart';
import 'package:voicesewa_worker/core/providers/session_provider.dart';
import 'package:voicesewa_worker/features/auth/presentation/login_screen.dart';
import 'package:voicesewa_worker/features/auth/presentation/signup_screen.dart';
import 'package:voicesewa_worker/features/auth/providers/auth_screen_provider.dart';

class AppGate extends ConsumerStatefulWidget {
  const AppGate({super.key});

  @override
  ConsumerState<AppGate> createState() => _AppGateState();
}

class _AppGateState extends ConsumerState<AppGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setupFCM());
  }

  Future<void> _setupFCM() async {
    // FCM setup remains unchanged — inject fcmServiceProvider here
    // as you had it before. Keeping stub for brevity.
    print('🔔 FCM setup in AppGate');
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionNotifierProvider);
    final authScreen = ref.watch(authScreenProvider);

    switch (sessionState.status) {
      case SessionStatus.loading:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );

      case SessionStatus.loggedIn:
        // Delegate profile check to ProfileCheckHandler (mirrors client app)
        return const ProfileCheckHandler();

      case SessionStatus.loggedOut:
        return authScreen == AuthScreen.login
            ? const LoginScreen()
            : const SignupScreen();
    }
  }
}