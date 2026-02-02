import 'package:flutter/material.dart';
import 'package:voicesewa_client/core/widgets/feedback/coming_soon_page.dart';
import 'package:voicesewa_client/features/auth/presentation/profile_form_screen.dart';
import 'package:voicesewa_client/features/history/presentation/requests_page.dart';
import 'package:voicesewa_client/features/home/presentation/home_page.dart';
import 'package:voicesewa_client/features/jobs/presentation/book_again_screen.dart';
import 'package:voicesewa_client/features/jobs/presentation/create_job_screen.dart';
import 'package:voicesewa_client/features/jobs/presentation/my_request_screen.dart';
import 'package:voicesewa_client/features/search/presentation/workers_page.dart';
import 'package:voicesewa_client/features/settings/presentation/settings_page.dart';
import 'package:voicesewa_client/features/settings/presentation/support_page.dart';
import 'package:voicesewa_client/features/voicebot/presentation/voicebot_chat.dart';

/// Centralized route names for the entire app
class RoutePaths {
  static const String home = '/home';
  static const String search = '/search';
  static const String voicebot = '/voicebot';
  static const String history = '/history';
  static const String book = '/book';
  static const String track = 'track';
  static const String settings = '/settings';
  static const String support = '/support';
  static const String login = '/loginPage';
  static const String signup = '/signupPage';
  static const String profileSetup = '/profile-setup';
  static const String comingSoon = '/comingSoonPage';
  static const String syncDebug = '/sync-debug';
  static const String createJob = '/create-job';
  static const String myRequests = '/my-requests';
  static const String bookAgain = '/book-again';
}

/// Global route configuration
class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    RoutePaths.home: (context) => const HomePage(),
    RoutePaths.search: (context) => const SuggestedWorkersPage(),
    RoutePaths.history: (context) => const RequestPage(),
    RoutePaths.settings: (context) => const SettingsPage(),
    RoutePaths.support: (context) => const SupportPage(),
    RoutePaths.voicebot: (context) => const VoiceBotPage(),
    RoutePaths.profileSetup: (context) => const ProfileSetupScreen(),
    RoutePaths.comingSoon: (context) => const ComingSoonPage(),
    RoutePaths.createJob: (context) => const CreateJobScreen(),
    RoutePaths.myRequests: (context) => const MyRequestsPage(),
    RoutePaths.bookAgain: (context) => const BookAgainPage(),
    // RoutePaths.syncDebug: (context) => const SyncDebugPage(),
  };
}
