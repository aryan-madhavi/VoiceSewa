import 'package:flutter/material.dart';
import 'package:voicesewa_worker/core/extensions/context_extensions.dart';
import 'package:voicesewa_worker/core/constants/helper_function.dart';
import 'settings_section_header.dart';

class PreferencesSection extends StatelessWidget {
  final bool notificationsEnabled;
  final bool darkMode;
  final ValueChanged<bool> onNotificationsChanged;
  final ValueChanged<bool> onDarkModeChanged;

  const PreferencesSection({
    super.key,
    required this.notificationsEnabled,
    required this.darkMode,
    required this.onNotificationsChanged,
    required this.onDarkModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: context.loc.preferences),
        const SizedBox(height: 10),
        settingsPageBuildSwitchTile(
          context.loc.pushNotifications,
          context.loc.receiveJobAlerts,
          notificationsEnabled,
          onNotificationsChanged,
        ),
        settingsPageBuildSwitchTile(
          context.loc.darkMode,
          context.loc.reduceEyeStrain,
          darkMode,
          onDarkModeChanged,
        ),
      ],
    );
  }
}
