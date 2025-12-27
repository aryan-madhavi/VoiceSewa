import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/core/providers/session_provider.dart';

class AuthService {
  final WidgetRef ref;

  AuthService(this.ref);

  /// Handle user login with Firebase and session management
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      // Firebase Authentication
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update session statex
      final sessionNotifier = ref.read(sessionNotifierProvider.notifier);
      await sessionNotifier.login(email.trim(), password);

      return null; // Success
    } on FirebaseAuthException catch (e) {
      return _getAuthErrorMessage(e);
    } catch (e) {
      return 'Unexpected error: ${e.toString()}';
    }
  }

  /// Handle user registration with Firebase and session management
  Future<String?> register({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      // Firebase Authentication
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(username.trim());

      // Update session state
      final sessionNotifier = ref.read(sessionNotifierProvider.notifier);
      await sessionNotifier.login(email.trim(), password);

      return null; // Success
    } on FirebaseAuthException catch (e) {
      return _getAuthErrorMessage(e);
    } catch (e) {
      return 'Unexpected error: ${e.toString()}';
    }
  }

  /// Get user-friendly error messages from Firebase Auth exceptions
  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      // Login errors
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-credential':
        return 'Invalid email or password';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later';

      // Registration errors
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled';

      // Common errors
      case 'invalid-email':
        return 'Invalid email address';
      case 'network-request-failed':
        return 'Network error. Please check your connection';

      default:
        return 'Authentication failed: ${e.message ?? e.code}';
    }
  }
}