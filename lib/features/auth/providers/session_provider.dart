import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:voicesewa_client/features/auth/data/database/auth_repository.dart';
import 'package:voicesewa_client/features/auth/providers/auth_provider.dart';

/// Session status enum
enum SessionStatus { 
  loading,    // Initial state, checking session
  loggedIn,   // User is logged in with valid session
  loggedOut   // No user or session expired
}

/// Session state notifier - manages user session lifecycle
class SessionNotifier extends StateNotifier<SessionStatus> {
  final AuthRepository _authRepository;

  SessionNotifier(this._authRepository) : super(SessionStatus.loading) {
    _init();
  }

  /// Initialize session on app start
  Future<void> _init() async {
    try {
      final valid = await _authRepository.isSessionValid();
      state = valid ? SessionStatus.loggedIn : SessionStatus.loggedOut;
    } catch (e) {
      print('Session initialization error: $e');
      state = SessionStatus.loggedOut;
    }
  }

  /// Login user and update session state
  Future<void> login(String username, String password) async {
    try {
      await _authRepository.login(username: username, password: password);
      state = SessionStatus.loggedIn;
    } catch (e) {
      print('Session login error: $e');
      rethrow;
    }
  }

  /// Logout current user and update session state
  Future<void> logout() async {
    try {
      final user = await _authRepository.getLoggedInUser();
      if (user != null) {
        final username = user['username'] as String;
        await _authRepository.logout(username);
      }
      state = SessionStatus.loggedOut;
    } catch (e) {
      print('Session logout error: $e');
      rethrow;
    }
  }

  /// Refresh current session (update timestamp)
  Future<void> refreshSession() async {
    try {
      final user = await _authRepository.getLoggedInUser();
      if (user != null) {
        final username = user['username'] as String;
        await _authRepository.refreshSession(username);
      }
    } catch (e) {
      print('Session refresh error: $e');
    }
  }

  /// Check and update session validity
  Future<void> validateSession() async {
    try {
      final valid = await _authRepository.isSessionValid();
      if (!valid && state == SessionStatus.loggedIn) {
        // Session expired, logout user
        state = SessionStatus.loggedOut;
      }
    } catch (e) {
      print('Session validation error: $e');
    }
  }
}

/// Session Notifier Provider - Uses auth repository from auth_provider.dart
final sessionNotifierProvider = StateNotifierProvider<SessionNotifier, SessionStatus>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SessionNotifier(repository);
});

/// Provider to get current session info
final currentSessionProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final status = ref.watch(sessionNotifierProvider);
  
  if (status != SessionStatus.loggedIn) {
    return null;
  }

  final repo = ref.watch(authRepositoryProvider);
  return await repo.getLoggedInUser();
});

/// Provider to check if user is logged in
final isLoggedInProvider = Provider<bool>((ref) {
  final status = ref.watch(sessionNotifierProvider);
  return status == SessionStatus.loggedIn;
});

/// Provider to get current username
final currentUsernameProvider = FutureProvider<String?>((ref) async {
  final session = await ref.watch(currentSessionProvider.future);
  return session?['username'] as String?;
});