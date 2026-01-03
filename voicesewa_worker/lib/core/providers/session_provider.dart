import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:voicesewa_worker/core/database/app_database.dart';
import 'package:voicesewa_worker/features/auth/data/database/auth_repository.dart';
import 'package:voicesewa_worker/features/sync/providers/sync_providers.dart'; // 👈 Add this import

enum SessionStatus { loading, loggedIn, loggedOut }

class SessionState {
  final SessionStatus status;
  final Map<String, dynamic>? user;
  final String? errorMessage;

  SessionState({required this.status, this.user, this.errorMessage});

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
  final Ref _ref; // 👈 Add Ref field

  SessionNotifier(
    this._authRepository,
    this._ref,
  ) // 👈 Accept Ref in constructor
  : super(SessionState(status: SessionStatus.loading)) {
    _checkSession();
  }

  Future<void> _checkSession() async {
    final isLoggedIn = await _authRepository.isUserLoggedIn();

    if (isLoggedIn) {
      final user = await _authRepository.getCurrentUser();
      state = SessionState(status: SessionStatus.loggedIn, user: user);

      // 👇 Trigger sync initialization
      // _initializeSync();
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
      state = SessionState(status: SessionStatus.loggedIn, user: user);

      // 👇 Trigger sync initialization after successful login
      // _initializeSync();
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
      state = SessionState(status: SessionStatus.loggedIn, user: user);

      // 👇 Trigger sync initialization after successful registration
      // _initializeSync();
    } else {
      state = SessionState(
        status: SessionStatus.loggedOut,
        errorMessage: result.message,
      );
    }
  }

  // 👇 Add this method to initialize sync
  // Future<void> _initializeSync() async {
  //   try {
  //     final userId = WorkerDatabase.currentUserId;

  //     if (userId == null) {
  //       print('⚠️ No userId available for sync initialization');
  //       return;
  //     }

  //     print('🔄 Triggering SyncService initialization from SessionNotifier...');
  //     // Just read the provider - it will auto-initialize
  //     _ref.read(syncServiceProvider(userId));
  //     print('✅ SyncService trigger sent');
  //   } catch (e) {
  //     print('⚠️ Failed to trigger SyncService: $e');
  //   }
  // }

  Future<void> logout() async {
    final userId = WorkerDatabase.currentUserId;

    await _authRepository.logout();

    if (userId != null) {
      print('🧹 Cleaning up database for user: $userId');
      await WorkerDatabase.closeUserDatabase(userId);
      print('✅ Database closed successfully');
    }

    state = SessionState(status: SessionStatus.loggedOut);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final sessionNotifierProvider =
    StateNotifierProvider<SessionNotifier, SessionState>((ref) {
      final authRepository = ref.watch(authRepositoryProvider);
      return SessionNotifier(authRepository, ref); // 👈 Pass ref to constructor
    });
