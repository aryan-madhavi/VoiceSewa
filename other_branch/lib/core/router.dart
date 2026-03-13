import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/call/domain/call_state.dart';
import '../features/call/presentation/active_call_screen.dart';
import '../features/call/presentation/home_screen.dart';
import '../features/call/presentation/incoming_call_screen.dart';
import '../features/call/presentation/outgoing_call_screen.dart';
import '../features/call/providers/call_providers.dart';
import '../features/settings/presentation/language_settings_screen.dart';

// ── ConsumerWidget wrappers so builders re-run when call state changes ──────
// GoRouter caches Page objects by key; when the URL doesn't change the builder
// is never re-invoked. ConsumerWidgets watch state directly and self-rebuild.

class _OutgoingCallRoute extends ConsumerWidget {
  const _OutgoingCallRoute();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(callControllerProvider).valueOrNull;
    if (phase is OutgoingPhase) return OutgoingCallScreen(phase: phase);
    return const HomeScreen();
  }
}

class _IncomingCallRoute extends ConsumerWidget {
  const _IncomingCallRoute();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(callControllerProvider).valueOrNull;
    if (phase is IncomingPhase) {
      return IncomingCallScreen(
        signal: CallSignal(
          sessionId: phase.sessionId,
          callerUid: phase.callerUid,
          receiverUid: '',
          callerLang: phase.callerLang,
          status: 'ringing',
        ),
      );
    }
    return const HomeScreen();
  }
}

class _ActiveCallRoute extends ConsumerWidget {
  const _ActiveCallRoute();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(callControllerProvider).valueOrNull;
    if (phase is ActivePhase) return ActiveCallScreen(phase: phase);
    if (phase is ConnectingPhase) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return const HomeScreen();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  // Listenable that triggers router re-evaluation when auth or call state changes.
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    refreshListenable: notifier,
    redirect: (context, state) {
      final authed = ref.read(authStateProvider).valueOrNull != null;
      final onLogin = state.matchedLocation == '/login';

      if (!authed) return onLogin ? null : '/login';
      if (onLogin) return '/';

      // Handle call phase redirects
      final phase = ref.read(callControllerProvider).valueOrNull;
      if (phase != null) {
        return switch (phase) {
          OutgoingPhase() => state.matchedLocation == '/call/outgoing' ? null : '/call/outgoing',
          IncomingPhase() => state.matchedLocation == '/call/incoming' ? null : '/call/incoming',
          ConnectingPhase() || ActivePhase() =>
            state.matchedLocation == '/call/active' ? null : '/call/active',
          EndedPhase() => '/',
          // Idle (or any unmatched phase) while on a call screen → go home.
          _ => state.matchedLocation.startsWith('/call/') ? '/' : null,
        };
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/',
        builder: (_, __) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'settings',
            builder: (_, __) => const LanguageSettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/call/outgoing',
        builder: (_, __) => const _OutgoingCallRoute(),
      ),
      GoRoute(
        path: '/call/incoming',
        builder: (_, __) => const _IncomingCallRoute(),
      ),
      GoRoute(
        path: '/call/active',
        builder: (_, __) => const _ActiveCallRoute(),
      ),
    ],
  );
});

/// Bridges Riverpod provider changes into GoRouter's Listenable refresh.
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
    _ref.listen(callControllerProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
}
