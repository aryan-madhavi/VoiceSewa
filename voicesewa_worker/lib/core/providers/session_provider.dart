import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:voicesewa_worker/core/database/app_database.dart';
import 'package:voicesewa_worker/core/providers/database_provider.dart';
import 'package:voicesewa_worker/features/auth/data/database/auth_repository.dart';
import 'package:voicesewa_worker/features/profile/providers/worker_profile_provider.dart';

enum SessionStatus { loading, loggedIn, loggedOut }

class SessionState {
  final SessionStatus status;
  final Map<String, dynamic>? user;
  final String? errorMessage;
  final bool isNewUser;

  SessionState({
    required this.status,
    this.user,
    this.errorMessage,
    this.isNewUser = false,
  });

  SessionState copyWith({
    SessionStatus? status,
    Map<String, dynamic>? user,
    String? errorMessage,
    bool? isNewUser,
  }) {
    return SessionState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
      isNewUser: isNewUser ?? this.isNewUser,
    );
  }
}

class SessionNotifier extends StateNotifier<SessionState> {
  final AuthRepository _authRepository;
  final Ref _ref;

  SessionNotifier(this._authRepository, this._ref)
    : super(SessionState(status: SessionStatus.loading)) {
    _checkSession();
  }

  Future<void> _checkSession() async {
    print('🔍 Checking user session...');

    final isLoggedIn = await _authRepository.isUserLoggedIn();

    if (isLoggedIn) {
      final user = await _authRepository.getCurrentUser();

      // --- FIX START: Initialize Database on Auto-Login ---
      if (user != null && user['email'] != null) {
        print(
          '🗄️ Initializing database for existing session: ${user['email']}',
        );
        WorkerDatabase.instanceForUser(user['email']);
        await WorkerDatabase.instance.database; // Ensure DB is ready
      }
      // --- FIX END ---

      print('✅ User is logged in: ${user?['email']}');

      // This is an existing session (auto-login), so NOT a new user
      state = SessionState(
        status: SessionStatus.loggedIn,
        user: user,
        isNewUser: false, // Returning user
      );
    } else {
      print('⚠️ No active session found');
      state = SessionState(status: SessionStatus.loggedOut);
    }
  }

  Future<void> login(String email, String password) async {
    print('🔑 Attempting login for: $email');
    state = state.copyWith(status: SessionStatus.loading);

    final result = await _authRepository.login(
      email: email,
      password: password,
    );

    if (result.success) {
      // --- FIX START: Initialize Database on Login ---
      print('🗄️ Initializing database for user: $email');
      WorkerDatabase.instanceForUser(email);
      await WorkerDatabase.instance.database; // Ensure DB is ready
      // --- FIX END ---

      final user = await _authRepository.getCurrentUser();
      print('✅ Login successful for: ${user?['email']}');

      // Login = returning user, NOT new
      state = SessionState(
        status: SessionStatus.loggedIn,
        user: user,
        isNewUser: false, // Returning user logging in
      );
    } else {
      print('❌ Login failed: ${result.message}');
      state = SessionState(
        status: SessionStatus.loggedOut,
        errorMessage: result.message,
      );
    }
  }

  Future<void> register(String email, String username, String password) async {
    print('📝 Attempting registration for: $email');
    state = state.copyWith(status: SessionStatus.loading);

    final result = await _authRepository.register(
      email: email,
      username: username,
      password: password,
    );

    if (result.success) {
      // --- FIX START: Initialize Database on Register ---
      print('🗄️ Initializing database for new user: $email');
      WorkerDatabase.instanceForUser(email);
      await WorkerDatabase.instance.database; // Ensure DB is ready
      // --- FIX END ---

      final user = await _authRepository.getCurrentUser();
      print('✅ Registration successful for: ${user?['email']}');

      // Registration = NEW USER who needs to complete profile
      state = SessionState(
        status: SessionStatus.loggedIn,
        user: user,
        isNewUser: true, // 🔥 KEY FIX: This is a new user!
      );
    } else {
      print('❌ Registration failed: ${result.message}');
      state = SessionState(
        status: SessionStatus.loggedOut,
        errorMessage: result.message,
      );
    }
  }

  Future<void> logout() async {
    final userId = WorkerDatabase.currentUserId;
    print('🚪 Logging out user: $userId');

    await _authRepository.logout();

    if (userId != null) {
      print('🧹 Cleaning up database for user: $userId');
      await WorkerDatabase.closeUserDatabase(userId);
      print('✅ Database closed successfully');
    }

    // Force Riverpod to forget the old database connection
    _ref.invalidate(sqfliteDatabaseProvider);

    // Also clear any cached profile data
    _ref.invalidate(profileCompletionProvider);
    _ref.invalidate(workerProfileProvider);

    print('✅ Logout complete');
    state = SessionState(status: SessionStatus.loggedOut);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final sessionNotifierProvider =
    StateNotifierProvider<SessionNotifier, SessionState>((ref) {
      final authRepository = ref.watch(authRepositoryProvider);
      return SessionNotifier(authRepository, ref);
    });
