// lib/features/auth/application/auth_providers.dart
//
// Owns all Firebase singleton providers and the current user stream.
// Every other feature that needs Firebase imports from here —
// nothing in this file imports from translate_call or any other feature.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import 'auth_controller.dart';

// ── Firebase singletons ───────────────────────────────────────────────────────

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (_) => FirebaseAuth.instance,
);

final firestoreProvider = Provider<FirebaseFirestore>(
  (_) => FirebaseFirestore.instance,
);

// ── Current user stream ───────────────────────────────────────────────────────

/// Streams the currently signed-in Firebase user.
/// Emits null when signed out.
/// Used by the router redirect and any screen that needs the user's uid/name.
final currentUserProvider = StreamProvider<User?>(
  (ref) => ref.watch(firebaseAuthProvider).authStateChanges(),
);

// ── Auth feature providers ────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(auth: ref.watch(firebaseAuthProvider)),
);

final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);