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
    print('🔔 FCM setup in AppGate');
  }

  @override
  Widget build(BuildContext context) {
    // Now reads from stream-derived provider — no manual state, no race conditions.
    final sessionStatus = ref.watch(sessionStatusProvider);
    final authScreen = ref.watch(authScreenProvider);

    switch (sessionStatus) {
      case SessionStatus.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));

      case SessionStatus.loggedIn:
        return const ProfileCheckHandler();

      case SessionStatus.loggedOut:
        // ValueKeys ensure Flutter reuses the same widget instance,
        // so controllers/fields survive provider rebuilds.
        return authScreen == AuthScreen.login
            ? const LoginScreen(key: ValueKey('login'))
            : const SignupScreen(key: ValueKey('signup'));
    }
  }
}
