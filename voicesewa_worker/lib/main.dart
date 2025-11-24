import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:voicesewa_worker/constants/core/color_constants.dart';
import 'package:voicesewa_worker/constants/core/string_constants.dart';
import 'package:voicesewa_worker/screens/core/root_scaffold.dart';
import 'package:voicesewa_worker/firebase_options.dart';
import 'package:voicesewa_worker/routes/navigation_routes.dart';
import 'package:voicesewa_worker/theme/light_theme.dart';

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
      home: RootScaffold(),
      routes: AppRoutes.routes,
    );
  }
}
