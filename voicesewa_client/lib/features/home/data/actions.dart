import 'package:flutter/material.dart';

enum QuickActions { again, myRequests, offers, help }

class ActionData {
  static final Map<QuickActions, List<dynamic>> quickActions = {
    QuickActions.again: [
      Colors.teal,
      Icons.refresh,
      'Book Again',
      '/comingSoonPage',
    ],
    QuickActions.myRequests: [
      Colors.deepOrange,
      Icons.assignment_outlined,
      'My Requests',
      '/comingSoonPage',
    ],
    QuickActions.offers: [
      Colors.purpleAccent,
      Icons.local_offer_outlined,
      'Offers',
      '/comingSoonPage',
    ],
    QuickActions.help: [
      Colors.blueGrey,
      Icons.support_agent,
      'Help & Support',
      '/comingSoonPage',
    ],
  };
}