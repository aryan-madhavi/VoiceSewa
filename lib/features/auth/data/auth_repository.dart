// lib/features/auth/data/auth_repository.dart
//
// Wraps FirebaseAuth and writes the initial users/{uid} Firestore document
// on sign-up so other users can discover each other in the contact list.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/constants.dart';
import '../domain/user_profile.dart';

class AuthRepository {
  AuthRepository({
    required FirebaseAuth      auth,
    required FirebaseFirestore firestore,
  })  : _auth      = auth,
        _firestore = firestore;

  final FirebaseAuth      _auth;
  final FirebaseFirestore _firestore;
  final _googleSignIn = GoogleSignIn();

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // ── Email / password sign-in ──────────────────────────────────────────────

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  // ── Email / password sign-up ──────────────────────────────────────────────
  // Creates the Firebase Auth account AND writes users/{uid} to Firestore
  // so the user appears in other users' contact lists immediately.

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email:    email,
      password: password,
    );

    await credential.user?.updateDisplayName(displayName);

    // Write Firestore user doc
    if (credential.user != null) {
      await _writeUserProfile(
        uid:         credential.user!.uid,
        displayName: displayName,
        email:       email,
      );
    }

    return credential;
  }

  // ── Google sign-in ────────────────────────────────────────────────────────
  // Uses merge:true so existing users don't lose their fcmToken or language.

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
      await _writeUserProfile(
        uid:         userCredential.user!.uid,
        displayName: userCredential.user!.displayName ?? googleUser.displayName ?? '',
        email:       userCredential.user!.email ?? googleUser.email,
        merge:       true, // don't overwrite existing language/fcmToken
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

  // ── Firestore write ───────────────────────────────────────────────────────

  Future<void> _writeUserProfile({
    required String uid,
    required String displayName,
    required String email,
    bool merge = false,
  }) async {
    // FIX (Bug B): Never write fcmToken here — UserProfile.toFirestore()
    // would write fcmToken:null (token unknown at sign-up time), which
    // overwrites any previously saved token even under merge:true because
    // the key is explicitly present. FcmService.saveToken() handles the
    // token via its authStateChanges() listener instead.
    final data = <String, dynamic>{
      'uid':         uid,
      'displayName': displayName,
      'email':       email,
      'language':    'hi-IN',
      'createdAt':   FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .set(data, SetOptions(merge: true));
  }
}