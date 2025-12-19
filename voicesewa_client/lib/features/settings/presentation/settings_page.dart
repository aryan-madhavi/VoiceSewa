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
            title: context.loc.userPreferences,  //"User Preferences",
            tiles: [
              SettingsTile(
                icon: Icons.language,
                title: context.loc.language,  //"Language",
                subtitle: context.loc.selectYourPreferredLanguage, //"Select your preferred language",
                onTap: (context, ref) => openLanguageSelector(context, ref),
              ),
              SettingsTile(
                icon: Icons.notifications_outlined,
                title: context.loc.notifications,  //"Notifications",
                trailing: const NotificationSwitch(),
              ),
              SettingsTile(
                icon: Icons.location_on_outlined,
                title: context.loc.manageSavedAddresses,  //"Manage Saved Addresses",
                onTap: manageAddresses,
              ),
              SettingsTile(
                icon: Icons.data_usage_outlined,
                title: context.loc.dataUsageAndOfflineCache,  //"Data Usage & Offline Cache",
                subtitle: context.loc.configureDownloadAndCacheLimits, //"Configure download and cache limits",
                onTap: openDataUsageSettings,
              ),
            ],
          ),
          SettingsSection(
            title: context.loc.appSettings,  //"App Settings",
            tiles: [
              SettingsTile(
                icon: Icons.dark_mode_outlined,
                title: context.loc.darkMode,  //"Dark Mode",
                trailing: const ThemeSwitch(),
              ),
              SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: context.loc.privacyPolicy,  //"Privacy Policy",
                onTap: openPrivacyPolicy,
              ),
              SettingsTile(
                icon: Icons.description_outlined,
                title: context.loc.termsAndConditions,  //"Terms & Conditions",
                onTap: openTerms,
              ),
            ],
          ),

          SettingsSection(
            title: context.loc.account,  //"Account",
            tiles: [
              SettingsTile(
                icon: Icons.logout,
                title: context.loc.logout,  //"Logout",
                iconColor: Colors.redAccent,
                onTap: logout,
              ),
              SettingsTile(
                icon: Icons.delete_forever_outlined,
                title: context.loc.deleteAccount,  //"Delete Account",
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