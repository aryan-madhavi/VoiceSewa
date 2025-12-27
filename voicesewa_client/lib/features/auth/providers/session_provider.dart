import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:voicesewa_client/features/auth/data/repositories/auth_repository.dart';
import 'package:voicesewa_client/features/auth/providers/auth_provider.dart';

enum SessionStatus { loading, loggedIn, loggedOut }

class SessionNotifier extends StateNotifier<SessionStatus> {
  final AuthRepository _authRepository;

  SessionNotifier(this._authRepository) : super(SessionStatus.loading) {
    _init();
  }

  Future<void> _init() async {
    final valid = await _authRepository.isSessionValid();
    state = valid ? SessionStatus.loggedIn : SessionStatus.loggedOut;
  }

  Future<void> login(String username, String password) async {
    await _authRepository.login(username: username, password: password);
    state = SessionStatus.loggedIn;
  }

  Future<void> logout() async {
    final user = await _authRepository.getLoggedInUser();
    if (user != null) {
      await _authRepository.logout(user['username']);
    }
    state = SessionStatus.loggedOut;
  }
}

// Provider for the AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dao = ref.read(dbLoginDaoProvider); // dbLoginDaoProvider returns DbLoginDao
  return AuthRepository(dao);
});

// SessionNotifier Provider
final sessionNotifierProvider =
    StateNotifierProvider<SessionNotifier, SessionStatus>((ref) {
  final repository = ref.read(authRepositoryProvider);
  return SessionNotifier(repository);
});
