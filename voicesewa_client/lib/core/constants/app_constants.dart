import 'package:flutter/material.dart';
import 'package:voicesewa_client/core/constants/string_constants.dart';
import 'package:voicesewa_client/core/widgets/coming_soon_widget.dart';
import 'package:voicesewa_client/presentation/home/screens/home_page.dart';

enum NavTab { home, search, speak, history, profile }

class AppConstants {

  static final Map<NavTab, List<dynamic>> pages = {
    NavTab.home: [
      Icon(Icons.home), 
      StringConstants.homeTitle, 
      HomePage()
    ],
    NavTab.search: [
      Icon(Icons.search),
      StringConstants.searchTitle,
      ComingSoon(),
    ],
    NavTab.speak: [
      SizedBox.shrink(), 
      '', 
      SizedBox.shrink()
    ],
    NavTab.history: [
      Icon(Icons.history),
      StringConstants.historyTitle,
      ComingSoon(),
    ],
    NavTab.profile: [
      Icon(Icons.person),
      StringConstants.profileTitle,
      ComingSoon(),
    ],
  };
  
}
