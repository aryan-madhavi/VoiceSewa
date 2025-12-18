import 'package:flutter/material.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import this
import 'package:voicesewa_worker/features/earnings/presentation/earnings_page.dart';
import 'package:voicesewa_worker/features/jobs/presentation/my_jobs_page.dart';
import 'package:voicesewa_worker/features/profile/presentation/profile_page.dart';
import 'package:voicesewa_worker/features/home/presentation/home_page.dart';

import '../extensions/context_extensions.dart';

// import '../../extensions/context_extensions.dart';
// import '../../l10n/app_localizations.dart';

enum NavTab { home, jobs, speak, earnings, profile }

class AppConstants {

  static Map<NavTab, List<dynamic>> getPages(BuildContext context) {
    // final loc = AppLocalizations.of(context)!;

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