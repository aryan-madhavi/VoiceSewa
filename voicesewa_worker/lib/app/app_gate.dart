import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_worker/core/widgets/layout/root_scaffold.dart';
// import 'package:voicesewa_worker/features/auth/presentation/login_screen.dart';
// import 'package:voicesewa_worker/core/providers/session_provider.dart';

class AppGate extends ConsumerWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Once SessionProvider is created, uncomment the logic below
    // final sessionStatus = ref.watch(sessionNotifierProvider);

    return const RootScaffold();

    /* switch (sessionStatus) {
      case SessionStatus.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case SessionStatus.loggedIn:
        return const RootScaffold();
      case SessionStatus.loggedOut:
        return const LoginScreen();
    }
    */
  }
}