import 'package:flutter/material.dart';
import 'package:voicesewa_client/core/screens/coming_soon_page.dart';
import 'package:voicesewa_client/presentation/home/screens/home_page.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/home': (context) => const HomePage(),
    '/loginPage': (context) => const Placeholder(),
    '/signupPage': (context) => const Placeholder(),
    '/comingSoonPage': (context) => const ComingSoonPage(),
  };
}