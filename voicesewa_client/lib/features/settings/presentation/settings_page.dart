import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/features/settings/presentation/widgets/settings_section.dart';
import 'package:voicesewa_client/features/settings/presentation/widgets/settings_switches.dart';
import 'package:voicesewa_client/features/settings/presentation/widgets/settings_tile.dart';

// Imports for your provider and extensions
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../core/constants/helper_functions.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          SettingsSection(
            title: "User Preferences",
            tiles: [
              SettingsTile(
                icon: Icons.language,
                title: "Language",
                subtitle: "Select your preferred language",
                onTap: (context, ref) => openLanguageSelector(context, ref),
              ),
              SettingsTile(
                icon: Icons.notifications_outlined,
                title: "Notifications",
                trailing: const NotificationSwitch(),
              ),
              SettingsTile(
                icon: Icons.location_on_outlined,
                title: "Manage Saved Addresses",
                onTap: manageAddresses,
              ),
              SettingsTile(
                icon: Icons.data_usage_outlined,
                title: "Data Usage & Offline Cache",
                subtitle: "Configure download and cache limits",
                onTap: openDataUsageSettings,
              ),
            ],
          ),
          SettingsSection(
            title: "App Settings",
            tiles: [
              SettingsTile(
                icon: Icons.dark_mode_outlined,
                title: "Dark Mode",
                trailing: const ThemeSwitch(),
              ),
              SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: "Privacy Policy",
                onTap: openPrivacyPolicy,
              ),
              SettingsTile(
                icon: Icons.description_outlined,
                title: "Terms & Conditions",
                onTap: openTerms,
              ),
            ],
          ),

          SettingsSection(
            title: "Account",
            tiles: [
              SettingsTile(
                icon: Icons.logout,
                title: "Logout",
                iconColor: Colors.redAccent,
                onTap: logout,
              ),
              SettingsTile(
                icon: Icons.delete_forever_outlined,
                title: "Delete Account",
                iconColor: Colors.redAccent,
                onTap: deleteAccount,
              ),
            ],
          ),
        ],
      ),
    );
  }

}