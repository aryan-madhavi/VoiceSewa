import 'package:flutter/material.dart';

/// Reusable section header for settings page
class SettingsSectionHeader extends StatelessWidget {
  final String title;
  final Color? color;

  const SettingsSectionHeader({super.key, required this.title, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: color ?? Colors.grey,
        fontSize: 14,
      ),
    );
  }
}
