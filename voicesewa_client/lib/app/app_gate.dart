import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/core/widgets/layout/root_scaffold.dart';
import 'package:voicesewa_client/features/auth/presentation/login_screen.dart';
import 'package:voicesewa_client/features/auth/providers/session_provider.dart';
import 'package:voicesewa_client/features/sync/presentation/sync_initializer.dart';

class AppGate extends ConsumerWidget {
  const AppGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionStatus = ref.watch(sessionNotifierProvider);

    switch (sessionStatus) {
      case SessionStatus.loading:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case SessionStatus.loggedIn:
        return const SyncInitializer(child: const RootScaffold());
      case SessionStatus.loggedOut:
        return const AuthScreen();
    }
  }
}
