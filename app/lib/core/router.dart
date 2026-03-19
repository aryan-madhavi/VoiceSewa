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

/// Exposed so CallTranslateApp can show dialogs via the root navigator context.
final rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authed = ref.read(authStateProvider).valueOrNull != null;
      final loc = state.matchedLocation;

      // Not signed in → always go to /login
      if (!authed) return loc == '/login' ? null : '/login';
      if (loc == '/login') return '/';

      // Signed in — check onboarding
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user != null && !user.isOnboarded && loc != '/onboarding') {
        return '/onboarding';
      }

      // Handle active call phase redirects
      final phase = ref.read(callControllerProvider).valueOrNull;
      if (phase != null) {
        return switch (phase) {
          OutgoingPhase() =>
            loc == '/call/outgoing' ? null : '/call/outgoing',
          IncomingPhase() =>
            loc == '/call/incoming' ? null : '/call/incoming',
          ConnectingPhase() || ActivePhase() =>
            loc == '/call/active' ? null : '/call/active',
          EndedPhase() => loc.startsWith('/call/') ? '/' : null,
          _ => loc.startsWith('/call/') ? '/' : null,
        };
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) =>
            const LanguageSettingsScreen(isOnboarding: true),
      ),
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
    _ref.listen(currentUserProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
}
