import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:voicesewa_worker/core/services/fcm_service.dart';
import 'package:voicesewa_worker/features/auth/data/repositories/auth_repository.dart';

enum SessionStatus { loading, loggedIn, loggedOut }

class SessionState {
  final SessionStatus status;
  final User? user;
  final String? errorMessage;

  const SessionState({required this.status, this.user, this.errorMessage});

  SessionState copyWith({
    SessionStatus? status,
    User? user,
    String? errorMessage,
  }) {
    return SessionState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

class SessionNotifier extends StateNotifier<SessionState> {
  final AuthRepository _authRepository;
  final Ref _ref;

  SessionNotifier(this._authRepository, this._ref)
    : super(const SessionState(status: SessionStatus.loading)) {
    _init();
  }

  void _init() {
    // Firebase Auth persists sessions natively.
    // Listen to auth state — fires immediately with current user or null.
    _authRepository.authStateChanges.listen((user) {
      if (user != null) {
        print('✅ Firebase session active: ${user.email}');
        state = SessionState(status: SessionStatus.loggedIn, user: user);
      } else {
        print('⚠️ No active Firebase session');
        state = const SessionState(status: SessionStatus.loggedOut);
      }
    });
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: SessionStatus.loading, errorMessage: null);

    final result = await _authRepository.login(
      email: email,
      password: password,
    );

    if (result.success) {
      print('✅ Login successful: ${result.user?.email}');
      // authStateChanges listener will update state automatically,
      // but we set it here too for immediate UI response.
      state = SessionState(status: SessionStatus.loggedIn, user: result.user);
    } else {
      print('❌ Login failed: ${result.message}');
      state = SessionState(
        status: SessionStatus.loggedOut,
        errorMessage: result.message,
      );
    }
  }

  Future<void> register(String email, String username, String password) async {
    state = state.copyWith(status: SessionStatus.loading, errorMessage: null);

    final result = await _authRepository.register(
      email: email,
      username: username,
      password: password,
    );

    if (result.success) {
      print('✅ Registration successful: ${result.user?.email}');
      state = SessionState(status: SessionStatus.loggedIn, user: result.user);
    } else {
      print('❌ Registration failed: ${result.message}');
      state = SessionState(
        status: SessionStatus.loggedOut,
        errorMessage: result.message,
      );
    }
  }

  Future<void> logout() async {
    print('🚪 Logging out...');

    // Clear FCM token from Firestore before signing out
    final uid = _authRepository.currentUser?.uid;
    if (uid != null) {
      await _ref.read(fcmServiceProvider).clearToken(uid);
    }

    await _authRepository.logout();
    // authStateChanges listener fires and sets loggedOut automatically.
    state = const SessionState(status: SessionStatus.loggedOut);
    print('✅ Logout complete');
  }
}

// ── Providers ──────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final sessionNotifierProvider =
    StateNotifierProvider<SessionNotifier, SessionState>((ref) {
      final repo = ref.watch(authRepositoryProvider);
      return SessionNotifier(repo, ref);
    });
