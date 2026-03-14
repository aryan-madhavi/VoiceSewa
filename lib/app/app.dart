import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/app/app_gate.dart';
import 'package:voicesewa_client/app/routes.dart';
import 'package:voicesewa_client/core/theme/light_theme.dart';
import 'package:voicesewa_client/features/call/domain/call_state.dart';
import 'package:voicesewa_client/features/call/presentation/active_call_screen.dart';
import 'package:voicesewa_client/features/call/presentation/incoming_call_screen.dart';
import 'package:voicesewa_client/features/call/presentation/outgoing_call_screen.dart';
import 'package:voicesewa_client/features/call/providers/call_providers.dart';

import '../core/l10n/app_localizations.dart';
import '../core/providers/language_provider.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appName,
      locale: locale,
      supportedLocales: const [
        Locale('en'), // English
        Locale('hi'), // Hindi
        Locale('mr'), // Marathi
        Locale('gu'), // Gujarati
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: lightThemeData,
      home: const _CallListener(child: AppGate()),
      routes: AppRoutes.routes,
    );
  }
}

/// Listens to [callControllerProvider] and imperatively pushes / removes
/// a call route onto the root Navigator so that call screens are proper
/// Navigator routes — giving them a full Overlay context (required by
/// Tooltip, FloatingActionButton, AppBar back-button, etc.).
class _CallListener extends ConsumerStatefulWidget {
  const _CallListener({required this.child});

  final Widget child;

  @override
  ConsumerState<_CallListener> createState() => _CallListenerState();
}

class _CallListenerState extends ConsumerState<_CallListener> {
  Route<void>? _callRoute;

  void _pushCallScreen() {
    if (_callRoute != null) return;
    _callRoute = MaterialPageRoute<void>(
      settings: const RouteSettings(name: '/call'),
      builder: (_) => const _CallScreenRouter(),
    );
    Navigator.of(context, rootNavigator: true).push(_callRoute!);
  }

  void _popCallScreen() {
    if (_callRoute == null) return;
    Navigator.of(context, rootNavigator: true).removeRoute(_callRoute!);
    _callRoute = null;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<CallPhase>>(callControllerProvider, (_, next) {
      final phase = next.asData?.value;
      if (phase == null) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (phase is IdlePhase || phase is EndedPhase) {
          _popCallScreen();
        } else {
          _pushCallScreen();
        }
      });
    });

    return widget.child;
  }
}

/// Watches [callControllerProvider] and renders the correct call screen
/// based on the current phase. Runs inside a real Navigator route so all
/// widgets (Tooltip, Overlay, etc.) work correctly.
class _CallScreenRouter extends ConsumerWidget {
  const _CallScreenRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(callControllerProvider).asData?.value;

    if (phase is OutgoingPhase) return OutgoingCallScreen(phase: phase);

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

    if (phase is ActivePhase) return ActiveCallScreen(phase: phase);

    // ConnectingPhase or brief transition
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Connecting…'),
          ],
        ),
      ),
    );
  }
}
