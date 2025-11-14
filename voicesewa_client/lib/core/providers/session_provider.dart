import 'package:flutter_riverpod/legacy.dart';
import 'package:voicesewa_client/features/auth/data/db_login.dart';

enum SessionStatus { loading, loggedIn, loggedOut }

class SessionNotifier extends StateNotifier<SessionStatus> {
  SessionNotifier() : super(SessionStatus.loading) {
    _init();
  }

  Future<void> _init() async {
    final valid = await DbLogin().isSessionValid();
    state = valid ? SessionStatus.loggedIn : SessionStatus.loggedOut;
  }

  Future<void> login(String username, String password) async {
    await DbLogin().setLoggedInUser(username: username, password: password);
    state = SessionStatus.loggedIn;
  }

  Future<void> logout() async {
    final user = await DbLogin().getLoggedInUser();
    if (user != null) {
      await DbLogin().logoutUser(user['username']);
    }
    state = SessionStatus.loggedOut;
  }
}

final sessionNotifierProvider =
    StateNotifierProvider<SessionNotifier, SessionStatus>(
        (ref) => SessionNotifier());
