import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:voicesewa_worker/core/extensions/context_extensions.dart';
import 'package:voicesewa_worker/core/constants/helper_function.dart';
import 'settings_section_header.dart';

class PreferencesSection extends StatefulWidget {
  const PreferencesSection({super.key});

  @override
  State<PreferencesSection> createState() => _PreferencesSectionState();
}

class _PreferencesSectionState extends State<PreferencesSection> {
  bool _notificationsEnabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationStatus();
  }

  Future<void> _loadNotificationStatus() async {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    if (mounted) {
      setState(() {
        _notificationsEnabled =
            settings.authorizationStatus == AuthorizationStatus.authorized;
        _loading = false;
      });
    }
  }

  Future<void> _handleNotificationToggle(bool value) async {
    if (value) {
      // Request permission
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final granted =
          settings.authorizationStatus == AuthorizationStatus.authorized;
      setState(() => _notificationsEnabled = granted);

      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Notifications blocked. Please enable them in device settings.',
            ),
          ),
        );
      }
    } else {
      // FCM doesn't let apps revoke permission programmatically.
      // Guide the user to device settings.
      setState(() => _notificationsEnabled = true); // keep as true
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'To disable notifications, go to your device Settings > App > Notifications.',
            ),
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: context.loc.preferences),
        const SizedBox(height: 10),
        _loading
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            : settingsPageBuildSwitchTile(
                context.loc.pushNotifications,
                context.loc.receiveJobAlerts,
                _notificationsEnabled,
                _handleNotificationToggle,
              ),
      ],
    );
  }
}
