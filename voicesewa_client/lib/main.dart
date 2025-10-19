import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/core/constants/color_constants.dart';
import 'package:voicesewa_client/core/constants/string_constants.dart';
import 'package:voicesewa_client/core/screens/root_scaffold.dart';
import 'package:voicesewa_client/firebase_options.dart';
import 'package:voicesewa_client/routes/navigation_routes.dart';

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
      theme: ThemeData(colorScheme: ColorConstants.colorScheme),
      home: RootScaffold(),
      routes: AppRoutes.routes,
    );
  }
}