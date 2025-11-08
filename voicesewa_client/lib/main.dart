import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/constants/core/color_constants.dart';
import 'package:voicesewa_client/constants/core/string_constants.dart';
import 'package:voicesewa_client/firebase_options.dart';
import 'package:voicesewa_client/routes/navigation_routes.dart';
import 'package:voicesewa_client/screens/core/app_gate.dart';
import 'package:voicesewa_client/theme/light_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: StringConstants.appName,
      theme: lightThemeData,
      home: const AppGate(),
      routes: AppRoutes.routes,
    );
  }
}