import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/src/core.dart';
import 'package:voicesewa_worker/app/app_gate.dart';
import 'package:voicesewa_worker/app/routes.dart';
import 'package:voicesewa_worker/core/constants/app_constants.dart';
import 'package:voicesewa_worker/core/theme/light_theme.dart';
import 'package:voicesewa_worker/core/providers/language_provider.dart';

import '../core/l10n/app_localizations.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appName,
      locale: locale,
      supportedLocales: AppConstants.supportedLanguages.map(
        (language) => Locale(language.code),
      ),
      // Locale('en'), // English
      // Locale('hi'), // Hindi
      // Locale('mr'), // Marathi
      // Locale('gu'), // Gujarati
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      theme: lightThemeData,
      home: const AppGate(),
      routes: AppRoutes.routes,
    );
  }
}
