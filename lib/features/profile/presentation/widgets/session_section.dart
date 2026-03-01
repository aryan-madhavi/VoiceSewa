import 'package:flutter/material.dart';
import 'package:voicesewa_worker/core/constants/helper_function.dart';
import 'package:voicesewa_worker/core/extensions/context_extensions.dart';
import 'settings_section_header.dart';

class SessionSection extends StatelessWidget {
  final VoidCallback onLogout;

  const SessionSection({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: context.loc.session),
        const SizedBox(height: 10),
        settingsPageBuildActionTile(
          context.loc.logOut,
          Icons.logout,
          onLogout,
          isDestructive: false,
        ),
      ],
    );
  }
}
