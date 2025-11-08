import 'package:flutter/material.dart';
import 'package:voicesewa_client/routes/navigation_routes.dart';

class Helpers {
  static String getValidRoute(String routeName, {String fallback = '/comingSoonPage'}) {
    return AppRoutes.routes.containsKey(routeName) ? routeName : fallback;
  }

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending' || 'scheduled':
        return Colors.orange;
      case 'in progress':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
