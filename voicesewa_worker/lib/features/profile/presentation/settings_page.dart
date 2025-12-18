import 'package:flutter/material.dart';

import '../../../core/constants/helper_function.dart';
import '../../../core/extensions/context_extensions.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
            context.loc.settings, // "Settings",
            style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
              context.loc.preferences, // "Preferences",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),
          settingsPageBuildSwitchTile(
              context.loc.pushNotifications, // "Push Notifications",
              context.loc.receiveJobAlerts, // "Receive job alerts",
              _notificationsEnabled, (val) {
            setState(() => _notificationsEnabled = val);
          }),
          settingsPageBuildSwitchTile(
              context.loc.darkMode, // "Dark Mode",
              context.loc.reduceEyeStrain, // "Reduce eye strain",
              _darkMode, (val) {
            setState(() => _darkMode = val);
          }),

          const SizedBox(height: 30),
          Text(
              context.loc.account, // "Account",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),
          settingsPageBuildActionTile(
              context.loc.changePassword, // "Change Password",
              Icons.lock_outline, () {}),
          settingsPageBuildActionTile(
              context.loc.language, // "Language",
              Icons.language, () {}),
          settingsPageBuildActionTile(
              context.loc.privacyPolicy, // "Privacy Policy",
              Icons.privacy_tip_outlined, () {}),

          const SizedBox(height: 30),
          settingsPageBuildActionTile(
              context.loc.deleteAccount, // "Delete Account",
              Icons.delete_outline, () {}, isDestructive: true),
        ],
      ),
    );
  }
}