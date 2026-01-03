import 'package:flutter/material.dart';
import 'package:voicesewa_worker/core/constants/helper_function.dart';
import 'settings_section_header.dart';

class SessionSection extends StatelessWidget {
  final VoidCallback onLogout;

  const SessionSection({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: 'Session'),
        const SizedBox(height: 10),
        settingsPageBuildActionTile(
          'Logout',
          Icons.logout,
          onLogout,
          isDestructive: false,
        ),
      ],
    );
  }
}
