import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_worker/core/constants/color_constants.dart';
import 'package:voicesewa_worker/core/constants/string_constants.dart';
import 'package:voicesewa_worker/core/screens/root_scaffold.dart';
import 'package:voicesewa_worker/firebase_options.dart';
import 'package:voicesewa_worker/routes/navigation_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer (
      builder: (context, ref, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: StringConstants.appName,
          theme: ThemeData(
            colorScheme: ColorConstants.colorScheme,
          ),
          home: RootScaffold(),
          routes: AppRoutes.routes,
        );
      }
    );
  }
}