import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_worker/features/auth/data/services/logout_service.dart';
import '../../../core/extensions/context_extensions.dart';
import 'widgets/preferences_section.dart';
import 'widgets/account_section.dart';
import 'widgets/session_section.dart';
import 'widgets/danger_zone_section.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _darkMode = false;

  Future<void> _handleLogout() async {
    final logoutHandler = LogoutHandler(ref: ref, context: context);
    final success = await logoutHandler.logout();

    if (success && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete Account'),
            ],
          ),
          content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Account deletion feature coming soon'),
                  ),
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // final userId = WorkerDatabase.currentUserId;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          context.loc.settings,
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Preferences Section
          PreferencesSection(
            notificationsEnabled: _notificationsEnabled,
            darkMode: _darkMode,
            onNotificationsChanged: (val) =>
                setState(() => _notificationsEnabled = val),
            onDarkModeChanged: (val) => setState(() => _darkMode = val),
          ),

          const SizedBox(height: 30),

          // Account Section
          const AccountSection(),

          const SizedBox(height: 30),

          // Sync Section
          // if (userId != null) SyncSection(userId: userId),

          const SizedBox(height: 30),

          // Session Section
          SessionSection(onLogout: _handleLogout),

          const SizedBox(height: 30),

          // Danger Zone
          DangerZoneSection(onDeleteAccount: _showDeleteAccountDialog),
        ],
      ),
    );
  }
}
