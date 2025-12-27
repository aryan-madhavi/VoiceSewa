import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:voicesewa_client/core/providers/session_provider.dart';
import 'package:voicesewa_client/features/auth/data/db_login.dart';


/// Handles user logout functionality with Firebase, SQL, and session management
class LogoutHandler {
  final WidgetRef ref;
  final BuildContext context;

  LogoutHandler({
    required this.ref,
    required this.context,
  });

  /// Performs complete logout operation from all sources
  /// Returns true if successful, false otherwise
  Future<bool> logout({bool showConfirmation = true}) async {
    if (showConfirmation) {
      final shouldLogout = await _showLogoutConfirmationDialog();
      if (shouldLogout != true) return false;
    }

    try {
      // Get current user email before signing out
      final currentUser = FirebaseAuth.instance.currentUser;
      final userEmail = currentUser?.email;

      // 1. Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // 2. Logout from SQL database
      if (userEmail != null) {
        await DbLogin().logoutUser(userEmail);
      }

      // 3. Clear session state via Riverpod
      final sessionNotifier = ref.read(sessionNotifierProvider.notifier);
      await sessionNotifier.logout();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }

      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return false;
    }
  }

  /// Shows confirmation dialog before logout
  Future<bool?> _showLogoutConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.logout, color: Colors.orange),
              SizedBox(width: 8),
              Text('Logout'),
            ],
          ),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}