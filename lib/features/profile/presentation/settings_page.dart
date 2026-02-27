import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_worker/features/auth/data/services/logout_service.dart';
import '../../../core/extensions/context_extensions.dart';
import 'widgets/preferences_section.dart';
import 'widgets/account_section.dart';
import 'widgets/session_section.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  Future<void> _handleLogout() async {
    final logoutHandler = LogoutHandler(ref: ref, context: context);
    final success = await logoutHandler.logout();

    if (success && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          // Notifications toggle — reads live FCM permission status
          const PreferencesSection(),

          const SizedBox(height: 30),

          // Account: change password, privacy policy
          const AccountSection(),

          const SizedBox(height: 30),

          // Logout
          SessionSection(onLogout: _handleLogout),
        ],
      ),
    );
  }
}
