import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:voicesewa_client/features/settings/presentation/widgets/settings_section.dart';
import 'package:voicesewa_client/features/settings/presentation/widgets/settings_switches.dart';
import 'package:voicesewa_client/features/settings/presentation/widgets/settings_tile.dart';
import 'package:voicesewa_client/features/voicebot/providers/speech_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // --- User Preferences ---
          SettingsSection(
            title: "User Preferences",
            tiles: [
              SettingsTile(
                icon: Icons.language,
                title: "Language",
                subtitle: "Select your preferred language",
                onTap: _openLanguageSelector,
              ),
              SettingsTile(
                icon: Icons.notifications_outlined,
                title: "Notifications",
                trailing: NotificationSwitch(),
              ),
              SettingsTile(
                icon: Icons.location_on_outlined,
                title: "Manage Saved Addresses",
                onTap: _manageAddresses,
              ),
              SettingsTile(
                icon: Icons.data_usage_outlined,
                title: "Data Usage & Offline Cache",
                subtitle: "Configure download and cache limits",
                onTap: _openDataUsageSettings,
              ),
            ],
          ),

          // --- App Settings ---
          SettingsSection(
            title: "App Settings",
            tiles: [
              SettingsTile(
                icon: Icons.dark_mode_outlined,
                title: "Dark Mode",
                trailing: ThemeSwitch(),
              ),
              SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: "Privacy Policy",
                onTap: _openPrivacyPolicy,
              ),
              SettingsTile(
                icon: Icons.description_outlined,
                title: "Terms & Conditions",
                onTap: _openTerms,
              ),
            ],
          ),

          // --- Account ---
          SettingsSection(
            title: "Account",
            tiles: [
              SettingsTile(
                icon: Icons.logout,
                title: "Logout",
                iconColor: Colors.redAccent,
                onTap: _logout,
              ),
              SettingsTile(
                icon: Icons.delete_forever_outlined,
                title: "Delete Account",
                iconColor: Colors.redAccent,
                onTap: _deleteAccount,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Dummy Handlers (replace with actual logic/navigation)
  void _openLanguageSelector(BuildContext context, WidgetRef ref) {
    final speechState = ref.watch(speechProvider);
    final List<LocaleName> defaultLocales = [
      LocaleName('en_US', 'English (United States)'),
      LocaleName('hi_IN', 'Hindi (India)'),
      LocaleName('mr_IN', 'Marathi (India)'),
      LocaleName('gu_IN', 'Gujarati (India)'),
    ];
    final List<LocaleName> speechLocales = [
      ...speechState.availableLocales,
      ...defaultLocales.where(
        (d) => !speechState.availableLocales.any((a) => a.localeId == d.localeId),
      ),
    ];
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: speechLocales.map((locale) {
            final isSelected = locale.localeId == speechState.localeId;
            return ListTile(
              title: Text(locale.name),
              trailing: isSelected
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () {
                // Update selected locale in Riverpod
                ref.read(speechProvider.notifier).setLocale(locale.localeId);
                Navigator.pop(context); // Close bottom sheet
              },
            );
          }).toList(),
        );
      },
    );
  }

  static void _manageAddresses(BuildContext context, WidgetRef ref) {}
  static void _openDataUsageSettings(BuildContext context, WidgetRef ref) {}
  static void _openPrivacyPolicy(BuildContext context, WidgetRef ref) {}
  static void _openTerms(BuildContext context, WidgetRef ref) {}
  static void _logout(BuildContext context, WidgetRef ref) {}
  static void _deleteAccount(BuildContext context, WidgetRef ref) {}
}
