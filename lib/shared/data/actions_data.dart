import 'package:flutter/material.dart';
import '../../core/extensions/context_extensions.dart';
import 'package:voicesewa_client/app/routes.dart';

enum Actions { again, myRequests, offers, help }

class ActionsData {
  static Map<Actions, List<dynamic>> actions(BuildContext context) {
    return {
      Actions.again: [
        Colors.teal,
        Icons.refresh,
        context.loc.bookAgain, // 'Book Again',
        RoutePaths.comingSoon,
      ],
      Actions.myRequests: [
        Colors.deepOrange,
        Icons.assignment_outlined,
        context.loc.myRequests, // 'My Requests',
        RoutePaths.comingSoon,
      ],
      Actions.offers: [
        Colors.purpleAccent,
        Icons.local_offer_outlined,
        context.loc.offers, // 'Offers',
        RoutePaths.comingSoon,
      ],
      Actions.help: [
        Colors.blueGrey,
        Icons.support_agent,
        context.loc.helpAndSupport, // 'Help & Support',
        RoutePaths.support,
      ],
    };
  }
}
