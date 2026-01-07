import 'package:flutter/material.dart';
import 'package:voicesewa_client/core/providers/navbar_page_provider.dart';
import 'package:voicesewa_client/app/routes.dart';

import '../extensions/context_extensions.dart';

class AppConstants {

  static Map<NavTab, List<dynamic>> pages(BuildContext context) {
    return {
      NavTab.home: [
        Icon(Icons.home),
        context.loc.homeTitle,
        RoutePaths.home,
      ],
      NavTab.search: [
        Icon(Icons.search),
        context.loc.searchTitle,
        RoutePaths.search,
      ],
      NavTab.voicebot: [
        SizedBox.shrink(),
        context.loc.voiceBotTitle,
        RoutePaths.voicebot,
      ],
      NavTab.history: [
        Icon(Icons.history),
        context.loc.historyTitle,
        RoutePaths.history,
      ],
      NavTab.settings: [
        Icon(Icons.settings),
        context.loc.settingsTitle,
        RoutePaths.settings,
      ],
    };
  }
}
