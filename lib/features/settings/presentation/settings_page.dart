import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/features/auth/data/services/logout_service.dart';
import 'package:voicesewa_client/features/settings/presentation/widgets/settings_section.dart';
import 'package:voicesewa_client/features/settings/presentation/widgets/settings_switches.dart';
import 'package:voicesewa_client/features/settings/presentation/widgets/settings_tile.dart';

// Imports for your provider and extensions
import '../../../../core/extensions/context_extensions.dart';

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
            tiles: [/* 
              SettingsTile(
                icon: Icons.language,
                title: context.loc.language,  //"Language",
                subtitle: context.loc.selectYourPreferredLanguage, //"Select your preferred language",
                onTap: (context, ref) => _openLanguageSelector(context, ref),
              ), */
              SettingsTile(
                icon: Icons.notifications_outlined,
                title: context.loc.notifications,  //"Notifications",
                trailing: const NotificationSwitch(),
              ),
              SettingsTile(
                icon: Icons.location_on_outlined,
                title: context.loc.manageSavedAddresses,  //"Manage Saved Addresses",
                onTap: _manageAddresses,
              ),
              SettingsTile(
                icon: Icons.data_usage_outlined,
                title: context.loc.dataUsageAndOfflineCache,  //"Data Usage & Offline Cache",
                subtitle: context.loc.configureDownloadAndCacheLimits, //"Configure download and cache limits",
                onTap: _openDataUsageSettings,
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
                onTap: _openPrivacyPolicy,
              ),
              SettingsTile(
                icon: Icons.description_outlined,
                title: context.loc.termsAndConditions,  //"Terms & Conditions",
                onTap: _openTerms,
              ),
            ],
          ),

          // --- Services Interaction ---
          // SettingsSection(
          //   title: "User Services", 
          //   tiles: [
          //     SettingsTile(
          //       icon: Icons.add_box,
          //       title: "Populate Services",
          //       iconColor: Colors.green,
          //       // onTap: insertTempServiceRequest,
          //     ),
          //     SettingsTile(
          //       icon: Icons.bug_report_outlined,
          //       title: "Open Debug",
          //       iconColor: Colors.blue,
          //       onTap: (BuildContext context, WidgetRef ref) => context.pushNamedTransition(routeName: RoutePaths.syncDebug, type: PageTransitionType.rightToLeft)
          //     ),
          //     SettingsTile(
          //       icon: Icons.sync,
          //       // leadingWidget: SyncFAB(),
          //       title: "Sync Pending Services",
          //       iconColor: Colors.green,
          //       onTap: null,
          //     ),
          //   ]
          // ),

          // --- Account ---
          SettingsSection(
            title: context.loc.account,  //"Account",
            tiles: [
              SettingsTile(
                icon: Icons.logout,
                title: context.loc.logout,  //"Logout",
                iconColor: Colors.redAccent,
                onTap: _logout,
              ),
              SettingsTile(
                icon: Icons.delete_forever_outlined,
                title: context.loc.deleteAccount,  //"Delete Account",
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
  static void _manageAddresses(BuildContext context, WidgetRef ref) {}
  static void _openDataUsageSettings(BuildContext context, WidgetRef ref) {}
  static void _openPrivacyPolicy(BuildContext context, WidgetRef ref) {}
  static void _openTerms(BuildContext context, WidgetRef ref) {}

    static void _logout(BuildContext context, WidgetRef ref) {
    // Schedule for after current frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) return;
      
      final logoutHandler = LogoutHandler(ref: ref, context: context);
      await logoutHandler.logout(showConfirmation: true);
    });
  }

  static void _deleteAccount(BuildContext context, WidgetRef ref) {}

}