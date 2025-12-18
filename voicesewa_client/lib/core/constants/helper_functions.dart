import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/app/routes.dart';

import '../extensions/context_extensions.dart';
import '../providers/language_provider.dart';

class Helpers {
  static String getValidRoute(
    String routeName, {
    String fallback = RoutePaths.comingSoon,
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

// settings_page
final languages = [
  {'value': 'en', 'name': 'English'},
  {'value': 'hi', 'name': 'हिंदी'},
  {'value': 'mr', 'name': 'मराठी'},
  {'value': 'gu', 'name': 'ગુજરાતી'},
];
void openLanguageSelector(BuildContext context, WidgetRef ref) {
  final currentLocale = ref.read(localeProvider);

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Text(
            context.loc.selectLanguage,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Divider(),
          ...languages.map((lang) {
            final code = lang['value']!;
            final name = lang['name']!;
            final isSelected = currentLocale.languageCode == code;

            return ListTile(
              title: Text(name),
              trailing: isSelected
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () {
                ref.read(localeProvider.notifier).changeLanguage(code);
                Navigator.pop(context);
              },
            );
          }),
          const SizedBox(height: 20),
        ],
      );
    },
  );
}
void manageAddresses(BuildContext context, WidgetRef ref) {}
void openDataUsageSettings(BuildContext context, WidgetRef ref) {}
void openPrivacyPolicy(BuildContext context, WidgetRef ref) {}
void openTerms(BuildContext context, WidgetRef ref) {}
void logout(BuildContext context, WidgetRef ref) {}
void deleteAccount(BuildContext context, WidgetRef ref) {}