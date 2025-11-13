import 'package:flutter/material.dart';
import 'package:voicesewa_client/core/constants/string_constants.dart';
import 'package:voicesewa_client/core/providers/navbar_page_provider.dart';
import 'package:voicesewa_client/core/routes/navigation_routes.dart';

class AppConstants {

  static final Map<NavTab, List<dynamic>> pages = {
    NavTab.home: [
      Icon(Icons.home), 
      StringConstants.homeTitle, 
      RoutePaths.home,
    ],
    NavTab.search: [
      Icon(Icons.search),
      StringConstants.searchTitle,
      RoutePaths.search,
    ],
    NavTab.speak: [
      SizedBox.shrink(), 
      '', 
      SizedBox.shrink()
    ],
    NavTab.history: [
      Icon(Icons.history),
      StringConstants.historyTitle,
      RoutePaths.history,
    ],
    NavTab.settings: [
      Icon(Icons.settings),
      StringConstants.settingsTitle,
      RoutePaths.settings,
    ],
  };
  
}
