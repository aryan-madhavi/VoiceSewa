import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_worker/core/constants/color_constants.dart';
import 'package:voicesewa_worker/core/providers/session_provider.dart';

/// Handles user logout with optional confirmation dialog.
class LogoutHandler {
  final WidgetRef ref;
  final BuildContext context;

  LogoutHandler({required this.ref, required this.context});

  /// Performs logout. Shows confirmation dialog if [showConfirmation] is true.
  Future<bool> logout({bool showConfirmation = true}) async {
    if (showConfirmation) {
      final confirmed = await _showConfirmationDialog();
      if (confirmed != true) return false;
    }

    try {
      await ref.read(authActionsProvider.notifier).logout();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully'),
            backgroundColor: ColorConstants.successGreen,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: ColorConstants.errorRed,
          ),
        );
      }
      return false;
    }
  }

  Future<bool?> _showConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout, color: ColorConstants.warningOrange),
            SizedBox(width: 8),
            Text('Logout'),
          ],
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: ColorConstants.warningOrange,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
