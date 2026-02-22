import 'package:firebase_auth/firebase_auth.dart';
import 'package:voicesewa_worker/features/auth/data/models/AuthResult.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Returns the currently signed-in Firebase user, or null.
  User? get currentUser => _auth.currentUser;

  /// Returns true if a Firebase session is active.
  bool get isLoggedIn => _auth.currentUser != null;

  /// Stream of auth state changes (login / logout events).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Register a new user with Firebase Auth.
  Future<AuthResult> register({
    required String email,
    required String username,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await credential.user?.updateDisplayName(username.trim());

      return AuthResult(
        success: true,
        message: 'Registration successful',
        user: credential.user,
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, message: _mapFirebaseError(e));
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Unexpected error: ${e.toString()}',
      );
    }
  }

  /// Sign in an existing user with Firebase Auth.
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      return AuthResult(
        success: true,
        message: 'Login successful',
        user: credential.user,
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, message: _mapFirebaseError(e));
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Unexpected error: ${e.toString()}',
      );
    }
  }

  /// Sign out from Firebase Auth.
  Future<void> logout() async {
    await _auth.signOut();
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
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
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled';
      case 'invalid-email':
        return 'Invalid email address';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      default:
        return e.message ?? 'Authentication failed';
    }
  }
}
