import 'package:flutter/material.dart';
import 'package:voicesewa_client/core/widgets/feedback/coming_soon_page.dart';
import 'package:voicesewa_client/features/history/presentation/requests_page.dart';
import 'package:voicesewa_client/features/home/presentation/home_page.dart';
import 'package:voicesewa_client/features/search/presentation/workers_page.dart';
import 'package:voicesewa_client/features/settings/presentation/settings_page.dart';

/// Centralized route names for the entire app
class RoutePaths {
  static const String home = '/home';
  static const String search = '/search';
  static const String speak = '/speak';
  static const String history = '/history';
  static const String settings = '/settings';
  static const String login = '/loginPage';
  static const String signup = '/signupPage';
  static const String comingSoon = '/comingSoonPage';
}

/// Global route configuration
class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    RoutePaths.home: (context) => const HomePage(),
    RoutePaths.search: (context) => const SuggestedWorkersPage(),
    RoutePaths.speak: (context) => const ComingSoonPage(), 
    RoutePaths.history: (context) => const RequestPage(),
    RoutePaths.settings: (context) => const SettingsPage(),
    RoutePaths.login: (context) => const Placeholder(),
    RoutePaths.signup: (context) => const Placeholder(),
    RoutePaths.comingSoon: (context) => const ComingSoonPage(),
  };
}
