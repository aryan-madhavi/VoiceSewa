import 'package:flutter/material.dart';
import 'package:voicesewa_worker/core/widgets/feedback/coming_soon_page.dart';
import 'package:voicesewa_worker/features/earnings/presentation/earnings_page.dart';
import 'package:voicesewa_worker/features/home/presentation/home_page.dart';
import 'package:voicesewa_worker/features/jobs/presentation/my_jobs_page.dart';
import 'package:voicesewa_worker/features/profile/presentation/profile_page.dart';
import 'package:voicesewa_worker/features/profile/presentation/worker_profile_form_page.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/home': (context) => const HomePage(),
    // '/loginPage': (context) => const LoginScreen(),
    // '/signupPage': (context) => const SignupScreen(),
    '/my_jobs': (context) => const MyJobsPage(),
    '/earnings': (context) => const EarningsPage(),
    '/profile': (context) => const ProfilePage(),
    '/profile_form': (context) => const WorkerProfileFormPage(),
    '/comingSoonPage': (context) => const ComingSoonPage(),
  };
}
