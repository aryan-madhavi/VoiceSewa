import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:voicesewa_client/features/auth/providers/auth_provider.dart';
import 'package:voicesewa_client/features/auth/providers/profile_form_provider.dart';
import 'package:voicesewa_client/features/auth/services/fcm_service.dart';

/// Handles user logout with Firebase Auth + FCM cleanup
class LogoutHandler {
  final WidgetRef ref;
  final BuildContext context;

  LogoutHandler({required this.ref, required this.context});

  // ── Public methods ─────────────────────────────────────────────────────────

  Future<bool> logout({bool showConfirmation = true}) async {
    if (showConfirmation) {
      final confirmed = await _showLogoutConfirmationDialog();
      if (confirmed != true) return false;
    }

    try {
      final auth = ref.read(firebaseAuthProvider);
      final uid = auth.currentUser?.uid;

      print('🚪 Logging out user...');

      if (uid != null) await _cleanupFCM(uid);
      _resetAuthState();
      await auth.signOut();

      print('✅ User logged out successfully');

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
      print('❌ Logout error: $e');
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

  Future<bool> logoutAndDeleteData({bool showConfirmation = true}) async {
    if (showConfirmation) {
      final confirmed = await _showDeleteDataConfirmationDialog();
      if (confirmed != true) return false;
    }

    try {
      final auth = ref.read(firebaseAuthProvider);
      final repo = ref.read(clientFirebaseRepositoryProvider);
      final uid = auth.currentUser?.uid;
      if (uid == null) throw Exception('No user logged in');

      print('🗑️ Deleting user data...');

      await _cleanupFCM(uid);
      await repo.deleteProfile(uid);
      _resetAuthState();
      await auth.signOut();

      print('✅ User data deleted and logged out');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out and data deleted successfully'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return true;
    } catch (e) {
      print('❌ Logout with data deletion error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return false;
    }
  }

  Future<bool> deleteAccount({
    bool showConfirmation = true,
    required String password,
  }) async {
    if (showConfirmation) {
      final confirmed = await _showDeleteAccountConfirmationDialog();
      if (confirmed != true) return false;
    }

    try {
      final auth = ref.read(firebaseAuthProvider);
      final repo = ref.read(clientFirebaseRepositoryProvider);
      final user = auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      print('🗑️ Deleting account...');

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      await _cleanupFCM(user.uid);
      await repo.deleteProfile(user.uid);
      _resetAuthState();
      await user.delete();

      print('✅ Account deleted');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deleted successfully'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
      return true;
    } on FirebaseAuthException catch (e) {
      final msg = e.code == 'wrong-password'
          ? 'Incorrect password'
          : e.code == 'requires-recent-login'
          ? 'Please logout and login again before deleting account'
          : 'Account deletion failed';

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
      return false;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account deletion failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  Future<void> _cleanupFCM(String uid) async {
    try {
      print('🔔 Cleaning up FCM...');
      // Uses the shared FcmService — clears Firestore token + deletes device token
      await ref.read(fcmServiceProvider).clearToken(uid);
      print('✅ FCM cleanup complete');
    } catch (e) {
      print('⚠️ FCM cleanup error (non-critical): $e');
    }
  }

  void _resetAuthState() {
    print('🔄 Resetting auth state...');
    ref.read(authLoadingProvider.notifier).state = false;
    ref.read(loginPasswordVisibleProvider.notifier).state = false;
    ref.read(registerPasswordVisibleProvider.notifier).state = false;
    ref.read(confirmPasswordVisibleProvider.notifier).state = false;
    ref.read(authModeProvider.notifier).state = true;
    ref.read(profileCompletionProvider.notifier).reset();
    ref.read(isNewRegistrationProvider.notifier).reset();
    print('✅ Auth state reset complete');
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────

  Future<bool?> _showLogoutConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteDataConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete All Data'),
          ],
        ),
        content: const Text(
          'Are you sure you want to logout and DELETE ALL YOUR DATA?\n\n'
          'This action cannot be undone!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete & Logout'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteAccountConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Account'),
          ],
        ),
        content: const Text(
          'Are you sure you want to PERMANENTLY DELETE YOUR ACCOUNT?\n\n'
          'This will delete:\n'
          '• Your Firebase Auth account\n'
          '• All your data in Firestore\n\n'
          'This action CANNOT BE UNDONE!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }
}
