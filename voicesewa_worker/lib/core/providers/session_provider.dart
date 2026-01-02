import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:voicesewa_worker/features/auth/data/database/auth_repository.dart';

enum SessionStatus { loading, loggedIn, loggedOut }

class SessionState {
  final SessionStatus status;
  final Map<String, dynamic>? user;
  final String? errorMessage;

  SessionState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  SessionState copyWith({
    SessionStatus? status,
    Map<String, dynamic>? user,
    String? errorMessage,
  }) {
    return SessionState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class SessionNotifier extends StateNotifier<SessionState> {
  final AuthRepository _authRepository;

  SessionNotifier(this._authRepository)
      : super(SessionState(status: SessionStatus.loading)) {
    _checkSession();
  }

  Future<void> _checkSession() async {
    final isLoggedIn = await _authRepository.isUserLoggedIn();
    
    if (isLoggedIn) {
      final user = await _authRepository.getCurrentUser();
      state = SessionState(
        status: SessionStatus.loggedIn,
        user: user,
      );
    } else {
      state = SessionState(status: SessionStatus.loggedOut);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: SessionStatus.loading);
    
    final result = await _authRepository.login(
      email: email,
      password: password,
    );
    
    if (result.success) {
      final user = await _authRepository.getCurrentUser();
      state = SessionState(
        status: SessionStatus.loggedIn,
        user: user,
      );
    } else {
      state = SessionState(
        status: SessionStatus.loggedOut,
        errorMessage: result.message,
      );
    }
  }

  Future<void> register(String email, String username, String password) async {
    state = state.copyWith(status: SessionStatus.loading);
    
    final result = await _authRepository.register(
      email: email,
      username: username,
      password: password,
    );
    
    if (result.success) {
      final user = await _authRepository.getCurrentUser();
      state = SessionState(
        status: SessionStatus.loggedIn,
        user: user,
      );
    } else {
      state = SessionState(
        status: SessionStatus.loggedOut,
        errorMessage: result.message,
      );
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    state = SessionState(status: SessionStatus.loggedOut);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final sessionNotifierProvider =
    StateNotifierProvider<SessionNotifier, SessionState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return SessionNotifier(authRepository);
});