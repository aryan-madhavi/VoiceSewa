import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:voicesewa_client/features/auth/providers/auth_provider.dart';
import 'package:voicesewa_client/features/auth/providers/profile_form_provider.dart';

/// Handles user logout functionality with Firebase Auth
/// No SQLite dependencies - pure Firebase approach
class LogoutHandler {
  final WidgetRef ref;
  final BuildContext context;

  LogoutHandler({required this.ref, required this.context});

  /// Performs logout from Firebase Auth
  /// Returns true if successful, false otherwise
  Future<bool> logout({bool showConfirmation = true}) async {
    if (showConfirmation) {
      final shouldLogout = await _showLogoutConfirmationDialog();
      if (shouldLogout != true) return false;
    }

    try {
      final auth = ref.read(firebaseAuthProvider);

      print('🚪 Logging out user...');

      // CRITICAL FIX: Reset all auth-related state BEFORE signing out
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

  /// Logout and delete all user data from Firestore
  /// WARNING: This permanently deletes the user's Firestore profile
  Future<bool> logoutAndDeleteData({bool showConfirmation = true}) async {
    if (showConfirmation) {
      final shouldDelete = await _showDeleteDataConfirmationDialog();
      if (shouldDelete != true) return false;
    }

    try {
      final auth = ref.read(firebaseAuthProvider);
      final repo = ref.read(clientFirebaseRepositoryProvider);
      final currentUser = auth.currentUser;

      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      print('🗑️ Deleting user data...');

      // Delete Firestore profile
      await repo.deleteProfile(currentUser.uid);
      print('✅ Firestore profile deleted');

      // CRITICAL FIX: Reset all auth-related state
      _resetAuthState();

      // Sign out from Firebase
      await auth.signOut();
      print('✅ User logged out');

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
            content: Text('Logout with data deletion failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return false;
    }
  }

  /// Delete account permanently (Firebase Auth + Firestore profile)
  /// WARNING: This cannot be undone!
  Future<bool> deleteAccount({
    bool showConfirmation = true,
    required String password,
  }) async {
    if (showConfirmation) {
      final shouldDelete = await _showDeleteAccountConfirmationDialog();
      if (shouldDelete != true) return false;
    }

    try {
      final auth = ref.read(firebaseAuthProvider);
      final repo = ref.read(clientFirebaseRepositoryProvider);
      final currentUser = auth.currentUser;

      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      print('🗑️ Deleting account...');

      // Re-authenticate before deleting
      final credential = EmailAuthProvider.credential(
        email: currentUser.email!,
        password: password,
      );

      await currentUser.reauthenticateWithCredential(credential);
      print('✅ Re-authenticated');

      // Delete Firestore profile first
      await repo.deleteProfile(currentUser.uid);
      print('✅ Firestore profile deleted');

      // CRITICAL FIX: Reset all auth-related state
      _resetAuthState();

      // Then delete Firebase Auth account
      await currentUser.delete();
      print('✅ Firebase Auth account deleted');

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
      print('❌ Account deletion error: ${e.code}');

      String errorMessage = 'Account deletion failed';
      if (e.code == 'wrong-password') {
        errorMessage = 'Incorrect password';
      } else if (e.code == 'requires-recent-login') {
        errorMessage = 'Please logout and login again before deleting account';
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return false;
    } catch (e) {
      print('❌ Account deletion error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account deletion failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return false;
    }
  }

  /// CRITICAL FIX: Reset all auth-related state to prevent stuck loading states
  void _resetAuthState() {
    print('🔄 Resetting auth state...');

    // Reset auth loading state
    ref.read(authLoadingProvider.notifier).state = false;

    // Reset password visibility states
    ref.read(loginPasswordVisibleProvider.notifier).state = false;
    ref.read(registerPasswordVisibleProvider.notifier).state = false;
    ref.read(confirmPasswordVisibleProvider.notifier).state = false;

    // Reset auth mode to login
    ref.read(authModeProvider.notifier).state = true;

    // Reset profile completion states
    ref.read(profileCompletionProvider.notifier).reset();
    ref.read(isNewRegistrationProvider.notifier).reset();

    print('✅ Auth state reset complete');
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
              style: FilledButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  /// Shows confirmation dialog before deleting data
  Future<bool?> _showDeleteDataConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.delete_forever, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete All Data'),
            ],
          ),
          content: const Text(
            'Are you sure you want to logout and DELETE ALL YOUR DATA from Firestore?\n\n'
            'This action cannot be undone!',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete & Logout'),
            ),
          ],
        );
      },
    );
  }

  /// Shows confirmation dialog before deleting account
  Future<bool?> _showDeleteAccountConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
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
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete Account'),
            ),
          ],
        );
      },
    );
  }
}
