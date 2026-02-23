import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:voicesewa_worker/features/auth/data/models/AuthResult.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Returns the currently signed-in Firebase user, or null.
  User? get currentUser => _auth.currentUser;

  /// Returns true if a Firebase session is active.
  bool get isLoggedIn => _auth.currentUser != null;

  /// Stream of auth state changes (login / logout events).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Register ────────────────────────────────────────────────────────────

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

  // ── Login ───────────────────────────────────────────────────────────────

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

  // ── Logout ──────────────────────────────────────────────────────────────
  // Order matters here:
  //   1. Grab uid BEFORE signing out (after signOut, currentUser is null)
  //   2. Delete FCM token from device (stops new push notifications)
  //   3. Remove fcm_token field from Firestore worker doc (server-side clean up)
  //   4. Sign out from Firebase Auth
  //   5. Wipe local Firestore cache (prevents next user seeing stale data)
  //
  // Steps 2–3 are fire-and-forget with try/catch so a network failure
  // never blocks the user from logging out.

  Future<void> logout() async {
    final uid = _auth.currentUser?.uid;

    // ── Step 1: Delete FCM token from device ──────────────────────────────
    // This unregisters the device so FCM stops delivering push messages
    // to this device for the logged-out account.
    try {
      await FirebaseMessaging.instance.deleteToken();
      print('✅ FCM token deleted from device');
    } catch (e) {
      // Non-fatal — user can still log out even if FCM cleanup fails
      print('⚠️ FCM token delete failed (non-fatal): $e');
    }

    // ── Step 2: Remove fcm_token from Firestore worker doc ─────────────
    // Prevents server from sending push notifications to a device that
    // no longer has an active session for this account.
    if (uid != null) {
      try {
        await _firestore.collection('workers').doc(uid).update({
          'fcm_token': FieldValue.delete(),
        });
        print('✅ FCM token removed from Firestore for worker: $uid');
      } catch (e) {
        // Non-fatal — Firestore may be offline; token will be overwritten
        // with a fresh one when the user logs back in anyway.
        print('⚠️ Firestore FCM token removal failed (non-fatal): $e');
      }
    }

    // ── Step 3: Sign out from Firebase Auth ───────────────────────────────
    // Done AFTER FCM cleanup so we still have a valid uid and auth context
    // for the Firestore update above.
    await _auth.signOut();
    print('✅ Firebase Auth signed out');

    // ── Step 4: Wipe local Firestore cache ────────────────────────────────
    // clearPersistence() must be called AFTER signOut and while Firestore
    // has no active listeners. Since signOut triggers authStateChanges →
    // sessionStatusProvider → AppGate rebuilds and unmounts all screens
    // (dropping all listeners), this is the safe point to clear.
    //
    // Why: Prevents worker A's job/profile data from leaking into
    // worker B's session on the same device.
    try {
      await _firestore.clearPersistence();
      print('✅ Firestore local cache cleared');
    } catch (e) {
      // clearPersistence() throws if there are still active listeners.
      // This should not happen after signOut + AppGate rebuild, but we
      // catch defensively so logout never fails visibly for the user.
      print('⚠️ Firestore cache clear failed (non-fatal): $e');
    }
  }

  // ── Firebase error mapping ──────────────────────────────────────────────

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
