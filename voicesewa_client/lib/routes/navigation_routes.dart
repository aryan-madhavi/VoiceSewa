import 'package:flutter/material.dart';
import 'package:voicesewa_client/screens/core/coming_soon_page.dart';
import 'package:voicesewa_client/screens/history/requests.dart';
import 'package:voicesewa_client/screens/home/home_page.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/home': (context) => const HomePage(),
    '/loginPage': (context) => const Placeholder(),
    '/signupPage': (context) => const Placeholder(),
    '/comingSoonPage': (context) => const ComingSoonPage(),
    '/history': (context) => RequestPage(),
  };
}