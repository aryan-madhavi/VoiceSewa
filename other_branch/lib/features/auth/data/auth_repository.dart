import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/app_user.dart';
import '../../../core/constants.dart';

class AuthRepository {
  AuthRepository(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<UserCredential> signUp(String email, String password) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);

  Future<void> signOut() => _auth.signOut();

  /// Fetch or create the Firestore user document.
  Future<AppUser> getOrCreateProfile(User firebaseUser) async {
    final ref = _firestore
        .collection(FirestoreCollections.users)
        .doc(firebaseUser.uid);
    final snap = await ref.get();
    if (snap.exists) {
      return AppUser.fromJson({...snap.data()!, 'uid': firebaseUser.uid});
    }
    final user = AppUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName ?? '',
    );
    await ref.set(user.toJson());
    return user;
  }

  /// Save language preference to Firestore.
  Future<void> updateLang(String uid, String lang) =>
      _firestore.collection(FirestoreCollections.users).doc(uid).update({'lang': lang});

  /// Fetch a user's language preference (used when setting up incoming call).
  Future<String> getLang(String uid) async {
    final snap = await _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .get();
    return (snap.data()?['lang'] as String?) ?? 'en-US';
  }
}

// ── Providers ──────────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(FirebaseAuth.instance, FirebaseFirestore.instance);
});

/// Raw Firebase auth state stream.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Resolved AppUser (null when signed out).
final currentUserProvider = FutureProvider<AppUser?>((ref) async {
  final firebaseUser = ref.watch(authStateProvider).valueOrNull;
  if (firebaseUser == null) return null;
  return ref.watch(authRepositoryProvider).getOrCreateProfile(firebaseUser);
});
