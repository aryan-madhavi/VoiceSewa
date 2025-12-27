import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/core/database/app_database.dart';
import 'package:voicesewa_client/features/auth/providers/session_provider.dart';

/// Authentication service - handles Firebase auth + local session
class AuthService {
  final WidgetRef ref;

  AuthService(this.ref);

  /// Handle user login with Firebase and session management
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 Starting login process for: $email');
      
      // 1. Firebase Authentication
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      print('✅ Firebase authentication successful');

      // 2. Initialize user-specific database
      final trimmedEmail = email.trim();
      ClientDatabase.instanceForUser(trimmedEmail);
      
      // Ensure database is created by accessing it once
      final db = await ClientDatabase.instance.database;
      print('✅ User database initialized: ${db.path}');

      // 3. Update session state (stores in local SQL)
      final sessionNotifier = ref.read(sessionNotifierProvider.notifier);
      await sessionNotifier.login(trimmedEmail, password);
      print('✅ Session state updated');

      return null; // Success
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase auth error: ${e.code}');
      return _getAuthErrorMessage(e);
    } catch (e) {
      print('❌ Login error: $e');
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
      print('📝 Starting registration process for: $email');
      
      // 1. Firebase Authentication
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      print('✅ Firebase registration successful');

      // 2. Update display name
      await userCredential.user?.updateDisplayName(username.trim());
      print('✅ Display name updated');

      // 3. Initialize user-specific database
      final trimmedEmail = email.trim();
      ClientDatabase.instanceForUser(trimmedEmail);
      
      // Ensure database is created
      final db = await ClientDatabase.instance.database;
      print('✅ User database created: ${db.path}');

      // 4. Update session state (stores in local SQL)
      final sessionNotifier = ref.read(sessionNotifierProvider.notifier);
      await sessionNotifier.login(trimmedEmail, password);
      print('✅ Session state updated');

      return null; // Success
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase registration error: ${e.code}');
      return _getAuthErrorMessage(e);
    } catch (e) {
      print('❌ Registration error: $e');
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