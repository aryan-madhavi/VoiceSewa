// lib/features/auth/application/auth_providers.dart

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

// ── Current Firebase Auth user ────────────────────────────────────────────────

final currentUserProvider = StreamProvider<User?>(
  (ref) => ref.watch(firebaseAuthProvider).authStateChanges(),
);

// ── Current user's Firestore profile ─────────────────────────────────────────
// Streams users/{uid} document. Used by HomeScreen to seed the language picker
// and by other features that need the user's display name / language.

final currentUserProfileProvider = StreamProvider<UserProfile?>(
  (ref) {
    final userAsync = ref.watch(currentUserProvider);
    final firestore = ref.watch(firestoreProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) return const Stream.empty();
        return firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .snapshots()
            .map((snap) => snap.exists ? UserProfile.fromFirestore(snap) : null);
      },
      loading: () => const Stream.empty(),
      error:   (_, __) => const Stream.empty(),
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