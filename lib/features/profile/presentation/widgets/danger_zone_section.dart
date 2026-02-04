import 'package:flutter/material.dart';
import 'package:voicesewa_worker/core/constants/helper_function.dart';
import 'package:voicesewa_worker/core/extensions/context_extensions.dart';
import 'settings_section_header.dart';

class DangerZoneSection extends StatelessWidget {
  final VoidCallback onDeleteAccount;

  const DangerZoneSection({super.key, required this.onDeleteAccount});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: 'Danger Zone', color: Colors.red),
        const SizedBox(height: 10),
        settingsPageBuildActionTile(
          context.loc.deleteAccount,
          Icons.delete_outline,
          onDeleteAccount,
          isDestructive: true,
        ),
      ],
    );
  }
}
