import 'package:flutter/material.dart';

enum QuickActions { request, myRequests, offers, help }

class HomeConstants {

  static final Map<QuickActions, List<dynamic>> actions = {
    QuickActions.request: [
      Icons.add_box_outlined,
      'Request Services',
      '/comingSoonPage',
    ],
    QuickActions.myRequests: [
      Icons.shopping_cart_outlined,
      'My Requests',
      '/comingSoonPage',
    ],
    QuickActions.offers: [
      Icons.local_offer_outlined,
      'Offers',
      '/comingSoonPage',
    ],
    QuickActions.help: [
      Icons.help_outline_outlined,
      'Help',
      '/comingSoonPage',
    ],
  };
}