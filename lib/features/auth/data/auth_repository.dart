// lib/features/auth/data/auth_repository.dart
//
// Wraps FirebaseAuth for all authentication operations AND writes the
// initial Firestore user profile document at users/{uid} on first sign-in.
//
// Firestore user doc schema:
//   uid, displayName, email, language (default "hi-IN"),
//   fcmToken (set later by FcmService), createdAt

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/constants.dart';
import '../domain/user_profile.dart';

class AuthRepository {
  AuthRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final _googleSignIn = GoogleSignIn();

  // ── Stream ────────────────────────────────────────────────────────────────

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // ── Firestore helper ──────────────────────────────────────────────────────

  /// Creates or merges a user profile document at users/{uid}.
  /// Safe to call multiple times — uses SetOptions(merge: true).
  Future<void> _upsertUserProfile({
    required String uid,
    required String displayName,
    required String email,
  }) async {
    final ref = _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid);

    // Only set createdAt if the doc doesn't exist yet
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set(
        UserProfile(
          uid:         uid,
          displayName: displayName,
          email:       email,
          language:    'hi-IN', // default; user can update in HomeScreen
          createdAt:   DateTime.now(),
        ).toFirestore(),
      );
    } else {
      // Update mutable fields in case name/email changed (e.g. Google profile update)
      await ref.set(
        {'displayName': displayName, 'email': email},
        SetOptions(merge: true),
      );
    }
  }

  // ── Email / password ──────────────────────────────────────────────────────

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    // Ensure profile exists (handles users who signed up before this code)
    if (credential.user != null) {
      await _upsertUserProfile(
        uid:         credential.user!.uid,
        displayName: credential.user!.displayName ?? email.split('@').first,
        email:       email,
      );
    }
    return credential;
  }

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email:    email,
      password: password,
    );
    // Set display name in Firebase Auth
    await credential.user?.updateDisplayName(displayName);

    // Create Firestore profile immediately
    if (credential.user != null) {
      await _upsertUserProfile(
        uid:         credential.user!.uid,
        displayName: displayName,
        email:       email,
      );
    }
    return credential;
  }

  // ── Google ────────────────────────────────────────────────────────────────

  Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken:     googleAuth.idToken,
    );
    final userCredential = await _auth.signInWithCredential(credential);

    if (userCredential.user != null) {
      await _upsertUserProfile(
        uid:         userCredential.user!.uid,
        displayName: userCredential.user!.displayName ?? googleUser.displayName ?? '',
        email:       userCredential.user!.email ?? googleUser.email,
      );
    }
    return userCredential;
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