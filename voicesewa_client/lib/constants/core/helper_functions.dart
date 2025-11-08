import 'package:flutter/material.dart';
import 'package:voicesewa_client/routes/navigation_routes.dart';

class Helpers {
  static String getValidRoute(
    String routeName, {
    String fallback = '/comingSoonPage',
  }) {
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

  // Date parsing
  static DateTime parseDate(String date) {
    final parts = date.split(' ');
    final monthMap = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
    };
    final day = int.parse(parts[1].replaceAll(',', ''));
    final month = monthMap[parts[0]]!;
    final year = int.parse(parts[2]);
    return DateTime(year, month, day);
  }
}
