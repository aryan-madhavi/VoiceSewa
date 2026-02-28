import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/features/auth/services/fcm_service.dart';
import 'package:voicesewa_client/shared/models/client_model.dart';
import '../firebase/client_firebase_repository.dart';

/// Authentication service - handles Firebase Auth + Firestore profile management + FCM
class AuthService {
  final WidgetRef ref;
  final FirebaseAuth _auth;
  final ClientFirebaseRepository _clientRepo;

  AuthService(
    this.ref, {
    FirebaseAuth? auth,
    ClientFirebaseRepository? clientRepo,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _clientRepo = clientRepo ?? ClientFirebaseRepository();

  // ── Login ──────────────────────────────────────────────────────────────────

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 Starting login process for: $email');

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = userCredential.user!.uid;
      print('✅ Firebase authentication successful — UID: $uid');

      // Save FCM token via the shared FcmService provider
      await ref.read(fcmServiceProvider).requestPermissionAndSave(uid);

      return null; // success
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase auth error: ${e.code}');
      return _getAuthErrorMessage(e);
    } catch (e) {
      print('❌ Login error: $e');
      return 'Unexpected error: ${e.toString()}';
    }
  }

  // ── Register ───────────────────────────────────────────────────────────────

  /// Registration only creates the Firebase Auth account.
  /// FCM token is saved later in ProfileSetupScreen after the profile doc exists.
  Future<String?> register({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      print('🔐 Starting registration process for: $email');

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await userCredential.user?.updateDisplayName(username.trim());
      print(
        '✅ Firebase registration successful — UID: ${userCredential.user?.uid}',
      );

      // FCM token will be saved in ProfileSetupScreen once profile doc exists
      return null; // success
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase registration error: ${e.code}');
      return _getAuthErrorMessage(e);
    } catch (e) {
      print('❌ Registration error: $e');
      return 'Unexpected error: ${e.toString()}';
    }
  }

  // ── Misc ───────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    try {
      await _auth.signOut();
      print('✅ User logged out successfully');
    } catch (e) {
      print('❌ Logout error: $e');
      rethrow;
    }
  }

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;
  String? get currentUserEmail => _auth.currentUser?.email;
  String? get currentUserId => _auth.currentUser?.uid;

  Future<bool> currentUserHasProfile() async {
    try {
      return await _clientRepo.currentUserHasProfile();
    } catch (e) {
      print('❌ Error checking profile: $e');
      return false;
    }
  }

  Future<ClientProfile?> getCurrentUserProfile() async {
    try {
      return await _clientRepo.getCurrentUserProfile();
    } catch (e) {
      print('❌ Error fetching profile: $e');
      return null;
    }
  }

  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return _getAuthErrorMessage(e);
    } catch (e) {
      return 'Unexpected error: ${e.toString()}';
    }
  }

  Future<String?> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'No user logged in';

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      return null;
    } on FirebaseAuthException catch (e) {
      return _getAuthErrorMessage(e);
    } catch (e) {
      return 'Unexpected error: ${e.toString()}';
    }
  }

  Future<String?> deleteAccount(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'No user logged in';

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      await _clientRepo.deleteProfile(user.uid);
      await user.delete();
      return null;
    } on FirebaseAuthException catch (e) {
      return _getAuthErrorMessage(e);
    } catch (e) {
      return 'Unexpected error: ${e.toString()}';
    }
  }

  // ── Error messages ─────────────────────────────────────────────────────────

  String _getAuthErrorMessage(FirebaseAuthException e) {
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
        return 'Email/password accounts are not enabled';
      case 'invalid-email':
        return 'Invalid email address';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      case 'expired-action-code':
        return 'Reset link has expired';
      case 'invalid-action-code':
        return 'Invalid or already used reset link';
      default:
        return 'Authentication failed: ${e.message ?? e.code}';
    }
  }
}
