import 'package:flutter/material.dart';
import 'package:voicesewa_worker/core/model/language_mdel.dart';
import 'package:voicesewa_worker/features/earnings/presentation/earnings_page.dart';
import 'package:voicesewa_worker/features/jobs/presentation/my_jobs_page.dart';
import 'package:voicesewa_worker/features/profile/presentation/profile_page.dart';
import 'package:voicesewa_worker/features/home/presentation/home_page.dart';
import 'package:voicesewa_worker/shared/data/service_data.dart';

import '../extensions/context_extensions.dart';

enum NavTab { home, jobs, voicebot, earnings, profile }

class AppConstants {
  static Map<NavTab, List<dynamic>> getPages(BuildContext context) {
    return {
      NavTab.home: [
        const Icon(Icons.home),
        context.loc.homeTitle,
        const HomePage(),
      ],
      NavTab.jobs: [
        const Icon(Icons.business_center),
        context.loc.jobsTitle,
        const MyJobsPage(),
      ],
      NavTab.voicebot: [
        SizedBox.shrink(),
        context.loc.voiceBotTitle,
        SizedBox.shrink(),
      ],
      NavTab.earnings: [
        const Icon(Icons.monetization_on),
        context.loc.earningsTitle,
        const EarningsPage(),
      ],
      NavTab.profile: [
        const Icon(Icons.person),
        context.loc.profileTitle,
        const ProfilePage(),
      ],
    };
  }

  // Language Selection Constants
  static const List<LanguageOption> supportedLanguages = [
    LanguageOption(code: 'en', displayName: 'English'),
    LanguageOption(code: 'hi', displayName: 'हिंदी'),
    LanguageOption(code: 'mr', displayName: 'मराठी'),
    LanguageOption(code: 'gu', displayName: 'ગુજરાતી'),
  ];

  // Use ServicesData.serviceNames for skill/service lists throughout the app.
  // e.g. ServicesData.serviceNames → ['Electrician', 'Plumber', ...]
}
