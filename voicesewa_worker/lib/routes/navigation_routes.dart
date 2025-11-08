import 'package:flutter/material.dart';
import 'package:voicesewa_worker/screens/core/coming_soon_page.dart';
import 'package:voicesewa_worker/screens/earnings/pages/earnings_page.dart';
import 'package:voicesewa_worker/screens/home/pages/home_page.dart';
import 'package:voicesewa_worker/screens/my_jobs/pages/my_jobs_page.dart';
import 'package:voicesewa_worker/screens/profile/pages/profile_page.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/home': (context) => const HomePage(),
    '/loginPage': (context) => const Placeholder(),
    '/signupPage': (context) => const Placeholder(),
    '/my_jobs': (context) => const MyJobsPage(),
    '/earnings': (context) => const EarningsPage(),
    '/profile': (context) => const ProfilePage(),
    '/comingSoonPage': (context) => const ComingSoonPage(),
  };
}