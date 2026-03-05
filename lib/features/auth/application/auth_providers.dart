// lib/features/auth/application/auth_providers.dart
//
// Owns all Firebase singleton providers, the current user stream,
// and the current user's Firestore profile stream.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants.dart';
import '../data/auth_repository.dart';
import '../domain/user_profile.dart';
import 'auth_controller.dart';

// ── Firebase singletons ───────────────────────────────────────────────────────

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (_) => FirebaseAuth.instance,
);

final firestoreProvider = Provider<FirebaseFirestore>(
  (_) => FirebaseFirestore.instance,
);

// ── Current Firebase Auth user stream ─────────────────────────────────────────

/// Streams the currently signed-in Firebase user (or null when signed out).
/// Used by the router redirect and any screen that needs the user's uid/name.
final currentUserProvider = StreamProvider<User?>(
  (ref) => ref.watch(firebaseAuthProvider).authStateChanges(),
);

// ── Current user's Firestore profile ─────────────────────────────────────────

/// Streams the current user's UserProfile document from Firestore.
/// Emits null when the user is not signed in or the doc hasn't loaded yet.
final currentUserProfileProvider = StreamProvider<UserProfile?>(
  (ref) {
    final authAsync = ref.watch(currentUserProvider);
    final firestore = ref.watch(firestoreProvider);

    return authAsync.when(
      data: (user) {
        if (user == null) return Stream.value(null);
        return firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .snapshots()
            .map((snap) => snap.exists ? UserProfile.fromFirestore(snap) : null);
      },
      loading: () => Stream.value(null),
      error:   (_, __) => Stream.value(null),
    );
  },
);

// ── Auth feature providers ────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    auth:      ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
  ),
);

final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);