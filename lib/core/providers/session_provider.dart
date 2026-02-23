import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_worker/features/auth/data/repositories/auth_repository.dart';

// ── Enums ──────────────────────────────────────────────────────────────────

enum SessionStatus { loading, loggedIn, loggedOut }

// ── Firebase Auth Stream Providers (same pattern as client app) ────────────

/// Raw Firebase Auth state stream — single source of truth.
/// Never manually overwritten, so no race conditions possible.
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Current Firebase user (derived from stream)
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateChangesProvider).value;
});

/// Session status derived purely from the stream — no manual state setting.
/// This is why the client app never has the flash/reset bug.
final sessionStatusProvider = Provider<SessionStatus>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  return authState.when(
    data: (user) =>
        user != null ? SessionStatus.loggedIn : SessionStatus.loggedOut,
    loading: () => SessionStatus.loading,
    error: (_, __) => SessionStatus.loggedOut,
  );
});

// ── Auth Repository Provider ───────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// ── Auth Actions Notifier ──────────────────────────────────────────────────
// Handles login/register/logout actions only.
// Does NOT touch session status — the stream above handles that automatically.

class AuthActionsNotifier extends Notifier<AsyncValue<String?>> {
  @override
  AsyncValue<String?> build() => const AsyncValue.data(null);

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();

    final repo = ref.read(authRepositoryProvider);
    final result = await repo.login(email: email, password: password);

    if (result.success) {
      print('✅ Login successful: ${result.user?.email}');
      // Stream fires automatically → sessionStatusProvider updates → AppGate navigates.
      state = const AsyncValue.data(null);
    } else {
      print('❌ Login failed: ${result.message}');
      // Error stored here only — sessionStatusProvider is untouched,
      // so AppGate never remounts LoginScreen and fields are preserved.
      state = AsyncValue.data(result.message);
    }
  }

  Future<void> register(String email, String username, String password) async {
    state = const AsyncValue.loading();

    final repo = ref.read(authRepositoryProvider);
    final result = await repo.register(
      email: email,
      username: username,
      password: password,
    );

    if (result.success) {
      print('✅ Registration successful: ${result.user?.email}');
      state = const AsyncValue.data(null);
    } else {
      print('❌ Registration failed: ${result.message}');
      state = AsyncValue.data(result.message);
    }
  }

  Future<void> logout() async {
    print('🚪 Logging out...');
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    state = const AsyncValue.data(null);
    print('✅ Logout complete');
  }

  void clearError() {
    state = const AsyncValue.data(null);
  }
}

final authActionsProvider =
    NotifierProvider<AuthActionsNotifier, AsyncValue<String?>>(() {
      return AuthActionsNotifier();
    });
