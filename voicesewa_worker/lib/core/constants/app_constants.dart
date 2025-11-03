import 'package:flutter/material.dart';
import 'package:voicesewa_worker/core/constants/string_constants.dart';
import 'package:voicesewa_worker/core/widgets/coming_soon_widget.dart';
import 'package:voicesewa_worker/presentation/home/screens/home_page.dart';

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
      ComingSoon(),
    ],
    NavTab.speak: [
      SizedBox(),
      '',
      SizedBox.shrink(),
    ],
    NavTab.earnings: [
      Icon(Icons.monetization_on),
      StringConstants.earningsTitle,
      ComingSoon(),
    ],
    NavTab.profile: [
      Icon(Icons.person),
      StringConstants.profileTitle,
      ComingSoon(),
    ],
  };
  
}

