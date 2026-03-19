import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/app_user.dart';
import '../../../core/constants.dart';

class AuthRepository {
  AuthRepository(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Phone Auth ──────────────────────────────────────────────────────────────

  /// Send an OTP to [phoneNumber] (E.164 format, e.g. '+919876543210').
  ///
  /// [onCodeSent]     — called when the SMS is dispatched; store verificationId.
  /// [onFailed]       — called on any error (invalid number, quota exceeded …)
  /// [onAutoVerified] — Android only: SMS Retriever API auto-fills the OTP.
  Future<void> sendOtp(
    String phoneNumber, {
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(FirebaseAuthException e) onFailed,
    void Function(PhoneAuthCredential credential)? onAutoVerified,
    // Pass the token from a previous sendOtp call to resend without consuming
    // extra SMS quota on the Firebase project.
    int? resendToken,
  }) {
    return _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      forceResendingToken: resendToken,
      verificationCompleted: (credential) async {
        if (onAutoVerified != null) {
          onAutoVerified(credential);
        } else {
          await _auth.signInWithCredential(credential);
        }
      },
      verificationFailed: onFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  /// Confirm the OTP entered by the user and sign them in.
  Future<UserCredential> confirmOtp(
      String verificationId, String smsCode) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      try {
        // Remove the FCM token from Firestore so this device stops receiving
        // call notifications for the logged-out user.
        await _firestore
            .collection(FirestoreCollections.users)
            .doc(uid)
            .update({'fcmToken': FieldValue.delete()});
        // Invalidate the local token so a fresh one is issued on next login.
        await FirebaseMessaging.instance.deleteToken();
      } catch (_) {
        // Best effort — sign out regardless.
      }
    }
    await _auth.signOut();
  }

  // ── Firestore profile ───────────────────────────────────────────────────────

  /// Fetch the Firestore profile, or create it on first sign-in.
  Future<AppUser> getOrCreateProfile(User firebaseUser) async {
    final ref = _firestore
        .collection(FirestoreCollections.users)
        .doc(firebaseUser.uid);
    final snap = await ref.get();
    if (snap.exists) {
      return AppUser.fromJson({...snap.data()!, 'uid': firebaseUser.uid});
    }
    // New user — create profile with isOnboarded:false so the router
    // redirects to the language-selection onboarding screen.
    final user = AppUser(
      uid: firebaseUser.uid,
      phoneNumber: firebaseUser.phoneNumber ?? '',
      displayName: firebaseUser.displayName ?? '',
      isOnboarded: false,
    );
    await ref.set(user.toJson());

    // Write a phone_index entry so lookupUidByPhone can do a direct document
    // read (O(1)) instead of a collection query that needs a Firestore index.
    if (user.phoneNumber.isNotEmpty) {
      await _firestore
          .collection(FirestoreCollections.phoneIndex)
          .doc(user.phoneNumber)
          .set({'uid': firebaseUser.uid});
    }

    return user;
  }

  /// Batch-lookup which E.164 phone numbers are registered on Vaani.
  /// Returns a map of phone → uid for those that exist in phone_index.
  Future<Map<String, String>> lookupUidsByPhones(List<String> phones) async {
    if (phones.isEmpty) return {};
    final results = <String, String>{};
    // Parallel reads — phone_index doc ID == E.164 number, O(1) per read.
    await Future.wait(phones.map((phone) async {
      try {
        final doc = await _firestore
            .collection(FirestoreCollections.phoneIndex)
            .doc(phone)
            .get();
        if (doc.exists) {
          final uid = doc.data()?['uid'] as String?;
          if (uid != null) results[phone] = uid;
        }
      } catch (_) {}
    }));
    return results;
  }

  /// Store the FCM token so the backend can send push notifications.
  Future<void> updateFcmToken(String uid, String token) => _firestore
      .collection(FirestoreCollections.users)
      .doc(uid)
      .update({'fcmToken': token});

  /// Mark the user as onboarded after language selection.
  Future<void> markOnboarded(String uid) => _firestore
      .collection(FirestoreCollections.users)
      .doc(uid)
      .update({'isOnboarded': true});

  /// Save language preference to Firestore.
  Future<void> updateLang(String uid, String lang) => _firestore
      .collection(FirestoreCollections.users)
      .doc(uid)
      .update({'lang': lang});

  /// Fetch a user's language preference (used when setting up incoming call).
  Future<String> getLang(String uid) async {
    final snap = await _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .get();
    return (snap.data()?['lang'] as String?) ?? 'en-IN';
  }

  /// Look up a UID by E.164 phone number.
  /// Returns null if the contact hasn't registered with Vaani.
  ///
  /// Uses phone_index/{phoneNumber} — a direct document read by ID.
  /// This avoids a Firestore collection query and composite index requirement.
  Future<String?> lookupUidByPhone(String phoneNumber) async {
    final doc = await _firestore
        .collection(FirestoreCollections.phoneIndex)
        .doc(phoneNumber)
        .get();
    if (!doc.exists) return null;
    return doc.data()?['uid'] as String?;
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
