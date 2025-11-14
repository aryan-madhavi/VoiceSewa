import 'package:flutter/material.dart';
import 'package:voicesewa_client/core/routes/navigation_routes.dart';

enum Actions { again, myRequests, offers, help }

class ActionsData {
  static final Map<Actions, List<dynamic>> actions = {
    Actions.again: [
      Colors.teal,
      Icons.refresh,
      'Book Again',
      RoutePaths.comingSoon,
    ],
    Actions.myRequests: [
      Colors.deepOrange,
      Icons.assignment_outlined,
      'My Requests',
      RoutePaths.comingSoon,
    ],
    Actions.offers: [
      Colors.purpleAccent,
      Icons.local_offer_outlined,
      'Offers',
      RoutePaths.comingSoon,
    ],
    Actions.help: [
      Colors.blueGrey,
      Icons.support_agent,
      'Help & Support',
      RoutePaths.comingSoon,
    ],
  };
}
