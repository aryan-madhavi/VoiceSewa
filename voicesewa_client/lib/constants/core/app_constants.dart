import 'package:flutter/material.dart';
import 'package:voicesewa_client/constants/core/string_constants.dart';
import 'package:voicesewa_client/screens/history/requests.dart';
import 'package:voicesewa_client/screens/search/workers_page.dart';
import 'package:voicesewa_client/screens/settings/settings_page.dart';
import 'package:voicesewa_client/screens/home/home_page.dart';

enum NavTab { home, search, speak, history, settings }

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
      SuggestedWorkersPage(),
    ],
    NavTab.speak: [
      SizedBox.shrink(), 
      '', 
      SizedBox.shrink()
    ],
    NavTab.history: [
      Icon(Icons.history),
      StringConstants.historyTitle,
      RequestPage(),
    ],
    NavTab.settings: [
      Icon(Icons.settings),
      StringConstants.settingsTitle,
      SettingsPage(),
    ],
  };
  
}
