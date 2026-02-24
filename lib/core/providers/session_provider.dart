import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:voicesewa_worker/features/auth/data/repositories/auth_repository.dart';

// ── Enums ──────────────────────────────────────────────────────────────────

enum SessionStatus { loading, loggedIn, loggedOut }

// ── Firebase Auth Stream Providers ────────────────────────────────────────

/// Raw Firebase Auth state stream — single source of truth.
/// Never manually overwritten, so no race conditions possible.
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Current Firebase user (derived from stream).
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateChangesProvider).value;
});

/// Session status derived purely from the stream — no manual state setting.
final sessionStatusProvider = Provider<SessionStatus>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  return authState.when(
    data: (user) =>
        user != null ? SessionStatus.loggedIn : SessionStatus.loggedOut,
    loading: () => SessionStatus.loading,
    error: (_, __) => SessionStatus.loggedOut,
  );
});

// ── FCM Init Guard ─────────────────────────────────────────────────────────
// Tracks which UID has had FCM initialized in the current session.
// Prevents requestPermissionAndSave from firing on every ProfileCheckHandler
// rebuild (which would overwrite other users' tokens on the same device).
// Resets to null on logout because authStateChanges fires → providers rebuild.

final fcmInitializedUidProvider = StateProvider<String?>((ref) {
  // Auto-reset when user logs out — watch auth state so this provider
  // is invalidated when the session changes.
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return null; // starts as null for each new login session
});
// ── Auth Repository Provider ───────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// ── Auth Actions Notifier ──────────────────────────────────────────────────
// Handles login / register / logout actions only.
// Session status is derived from the Firebase Auth stream — never set manually.

class AuthActionsNotifier extends Notifier<AsyncValue<String?>> {
  @override
  AsyncValue<String?> build() => const AsyncValue.data(null);

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();

    final repo = ref.read(authRepositoryProvider);
    final result = await repo.login(email: email, password: password);

    if (result.success) {
      print('✅ Login successful: ${result.user?.email}');
      state = const AsyncValue.data(null);
    } else {
      print('❌ Login failed: ${result.message}');
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

  // ── Logout ─────────────────────────────────────────────────────────────
  // Full cleanup sequence (see auth_repository.dart for step-by-step detail):
  //   1. Delete FCM token from device
  //   2. Remove fcm_token from Firestore worker doc
  //   3. Firebase Auth signOut  ← triggers authStateChanges stream
  //   4. Firestore clearPersistence  ← safe now (stream fired, listeners drop)
  //
  // The authStateChanges stream fires after step 3, which causes
  // sessionStatusProvider → loggedOut → AppGate navigates to LoginScreen.
  // All Riverpod providers are invalidated automatically by the navigation
  // rebuild, so no stale provider state leaks to the next session.

  Future<void> logout() async {
    print('🚪 Logging out — starting cleanup sequence...');
    state = const AsyncValue.loading();

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.logout(); // Full cleanup: FCM + signOut + cache wipe
      state = const AsyncValue.data(null);
      print('✅ Logout complete — all cleanup done');
    } catch (e) {
      // Even if cleanup partially fails, auth signOut always runs first
      // so the user is always logged out visually.
      print('⚠️ Logout cleanup error (user still signed out): $e');
      state = const AsyncValue.data(null);
    }
  }

  void clearError() {
    state = const AsyncValue.data(null);
  }
}

final authActionsProvider =
    NotifierProvider<AuthActionsNotifier, AsyncValue<String?>>(() {
      return AuthActionsNotifier();
    });
