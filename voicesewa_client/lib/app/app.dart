import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/app/app_gate.dart';
import 'package:voicesewa_client/core/constants/string_constants.dart';
import 'package:voicesewa_client/app/routes.dart';
import 'package:voicesewa_client/core/theme/light_theme.dart';

import '../core/extensions/context_extensions.dart';
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
      home: AppGate(),
      routes: AppRoutes.routes,
    );
  }
}