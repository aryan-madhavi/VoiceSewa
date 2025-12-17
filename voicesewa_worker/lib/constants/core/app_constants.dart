import 'package:flutter/material.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import this
import 'package:voicesewa_worker/screens/earnings/pages/earnings_page.dart';
import 'package:voicesewa_worker/screens/my_jobs/pages/my_jobs_page.dart';
import 'package:voicesewa_worker/screens/profile/pages/profile_page.dart';
import 'package:voicesewa_worker/screens/home/pages/home_page.dart';

import '../../extensions/context_extensions.dart';
import '../../l10n/app_localizations.dart';

enum NavTab { home, jobs, speak, earnings, profile }

class AppConstants {

  static Map<NavTab, List<dynamic>> getPages(BuildContext context) {
    // final loc = AppLocalizations.of(context)!;

    return {
      NavTab.home: [
        const Icon(Icons.home),
        context.loc.homeTitle, // Dynamic String
        const HomePage(),
      ],
      NavTab.jobs: [
        const Icon(Icons.business_center),
        context.loc.jobsTitle,
        const MyJobsPage(),
      ],
      NavTab.speak: [
        const SizedBox(),
        '',
        const SizedBox.shrink(),
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
}