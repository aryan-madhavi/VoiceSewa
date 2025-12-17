import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:voicesewa_worker/constants/core/color_constants.dart';
import 'package:voicesewa_worker/constants/core/string_constants.dart';
import 'package:voicesewa_worker/l10n/app_localizations_en.dart';
import 'package:voicesewa_worker/screens/core/root_scaffold.dart';
import 'package:voicesewa_worker/firebase_options.dart';
import 'package:voicesewa_worker/routes/navigation_routes.dart';
import 'package:voicesewa_worker/theme/light_theme.dart';
import 'package:voicesewa_worker/providers/language_provider.dart';

import 'extensions/context_extensions.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appName,
      debugShowCheckedModeBanner: false,
      // title: context.loc.appName,
      theme: lightThemeData,
      locale: locale, //connecting to provider form this
      supportedLocales: const[
        Locale('en'), //English
        Locale('hi'), //Hindi
        Locale('mr'), //Marathi
        Locale('gu'), //Gujarati
      ],
      localizationsDelegates: const[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: RootScaffold(),
      routes: AppRoutes.routes,
    );
  }
}
