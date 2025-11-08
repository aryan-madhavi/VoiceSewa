import 'package:flutter/material.dart';
import 'package:voicesewa_worker/constants/core/string_constants.dart';
import 'package:voicesewa_worker/screens/earnings/pages/earnings_page.dart';
import 'package:voicesewa_worker/screens/my_jobs/pages/my_jobs_page.dart';
import 'package:voicesewa_worker/screens/profile/pages/profile_page.dart';
// import 'package:voicesewa_worker/widgets/core/coming_soon_widget.dart';
import 'package:voicesewa_worker/screens/home/pages/home_page.dart';

enum NavTab { home, jobs, speak, earnings, profile }

class AppConstants {

  static final Map<NavTab, List<dynamic>> pages = {
    NavTab.home: [
      Icon(Icons.home),
      StringConstants.homeTitle,
      HomePage(),
    ],
    NavTab.jobs: [
      Icon(Icons.business_center),
      StringConstants.jobsTitle,
      MyJobsPage(),
    ],
    NavTab.speak: [
      SizedBox(),
      '',
      SizedBox.shrink(),
    ],
    NavTab.earnings: [
      Icon(Icons.monetization_on),
      StringConstants.earningsTitle,
      EarningsPage(),
    ],
    NavTab.profile: [
      Icon(Icons.person),
      StringConstants.profileTitle,
      ProfilePage(),
    ],
  };
  
}

