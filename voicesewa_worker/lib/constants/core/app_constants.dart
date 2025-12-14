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

  static bool flag = false;

  static const Color kPrimaryBlue = Color(0xFF0056D2);
  static const Color kTextDark = Color(0xFF2D3436);
  static const Color kTextGrey = Color(0xFF757575);
  static const Color kUrgentRed = Color(0xFFE74C3C);
  static const Color kNewBlue = Color(0xFF3498DB);
}

