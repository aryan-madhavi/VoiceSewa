// lib/features/auth/application/auth_controller.dart
//
// Notifier that wraps AuthRepository actions and exposes loading/error state.
// State is an AsyncValue<void> — UI watches it to show spinners and errors.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import 'auth_providers.dart';

class AuthController extends AsyncNotifier<void> {
  late AuthRepository _repo;

  @override
  Future<void> build() async {
    _repo = ref.watch(authRepositoryProvider);
  }

  // ── Sign in ───────────────────────────────────────────────────────────────

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.signInWithEmail(email: email, password: password),
    );
  }

  // ── Sign up ───────────────────────────────────────────────────────────────

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.signUpWithEmail(
        email:       email,
        password:    password,
        displayName: displayName,
      ),
    );
  }

  // ── Google ────────────────────────────────────────────────────────────────

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.signInWithGoogle());
  }

  // ── Sign out ──────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repo.signOut);
  }

  // ── Password reset ────────────────────────────────────────────────────────

  Future<void> sendPasswordReset(String email) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.sendPasswordResetEmail(email),
    );
  }

  // ── Readable error message ────────────────────────────────────────────────

  static String friendlyError(Object error) {
    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'user-not-found'      => 'No account found for that email.',
        'wrong-password'      => 'Incorrect password.',
        'invalid-credential'  => 'Incorrect email or password.',
        'email-already-in-use'=> 'An account already exists with that email.',
        'weak-password'       => 'Password must be at least 6 characters.',
        'invalid-email'       => 'Please enter a valid email address.',
        'too-many-requests'   => 'Too many attempts. Try again later.',
        'network-request-failed' => 'No internet connection.',
        _                     => error.message ?? 'Authentication failed.',
      };
    }
    return error.toString();
  }
}