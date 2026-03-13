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
      builder: (context, child) => _CallOverlay(child: child!),
      home: AppGate(),
      routes: AppRoutes.routes,
    );
  }
}

/// Renders call screens (outgoing / incoming / active) as a full-screen overlay
/// on top of the entire navigation stack. The overlay is driven purely by
/// [callControllerProvider] state so it works from any screen in the app.
class _CallOverlay extends ConsumerWidget {
  const _CallOverlay({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callPhaseAsync = ref.watch(callControllerProvider);

    return callPhaseAsync.maybeWhen(
      data: (phase) {
        if (phase is IdlePhase || phase is EndedPhase) return child;

        return Stack(
          children: [
            child,
            Positioned.fill(child: _buildCallScreen(phase)),
          ],
        );
      },
      orElse: () => child,
    );
  }

  Widget _buildCallScreen(CallPhase phase) {
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
    // ConnectingPhase — show a simple loading screen
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
