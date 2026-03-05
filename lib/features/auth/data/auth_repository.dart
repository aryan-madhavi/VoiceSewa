// lib/features/auth/data/auth_repository.dart
//
// Wraps FirebaseAuth for all authentication operations:
//   - Email + password sign-in / sign-up
//   - Google sign-in
//   - Sign out
//   - Auth state stream
//   - Display name update (called after sign-up)

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  AuthRepository({required FirebaseAuth auth})
      : _auth = auth;

  final FirebaseAuth _auth;
  final _googleSignIn = GoogleSignIn();

  // ── Stream ────────────────────────────────────────────────────────────────

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // ── Email / password ──────────────────────────────────────────────────────

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email:    email,
      password: password,
    );
    // Set display name immediately so it's available in CallSession.callerName
    await credential.user?.updateDisplayName(displayName);
    return credential;
  }

  // ── Google ────────────────────────────────────────────────────────────────

  Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // user cancelled

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken:     googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  // ── Sign out ──────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // ── Password reset ────────────────────────────────────────────────────────

  Future<void> sendPasswordResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email: email);
}