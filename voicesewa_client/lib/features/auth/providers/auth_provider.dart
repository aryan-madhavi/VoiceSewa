import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:voicesewa_client/features/auth/data/daos/db_login_dao.dart';
import 'package:voicesewa_client/features/auth/data/repositories/auth_repository.dart';

// ==================== BASE PROVIDERS ====================

/// DAO Provider - Singleton instance
final dbLoginDaoProvider = Provider<DbLoginDao>((ref) {
  return DbLoginDao();
});

/// Repository Provider - Uses DAO
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dao = ref.watch(dbLoginDaoProvider);
  return AuthRepository(dao);
});

// ==================== DATA PROVIDERS ====================

/// Provider to get currently logged-in user
final loggedInUserProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  return await repo.getLoggedInUser();
});

/// Provider to check if session is valid
final sessionValidProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  return await repo.isSessionValid();
});

/// Provider to get total user count
final totalUsersProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  return await repo.getTotalUsers();
});

// ==================== UI STATE PROVIDERS ====================

/// Toggle between login and register mode (true = login, false = register)
final authModeProvider = StateProvider<bool>((ref) => true);

/// Loading state for auth operations
final authLoadingProvider = StateProvider<bool>((ref) => false);

/// Password visibility toggles
final loginPasswordVisibleProvider = StateProvider<bool>((ref) => false);
final registerPasswordVisibleProvider = StateProvider<bool>((ref) => false);
final confirmPasswordVisibleProvider = StateProvider<bool>((ref) => false);

// ==================== HELPER PROVIDERS ====================

/// Provider to check if a specific user exists
final userExistsProvider = FutureProvider.family<bool, String>((ref, username) async {
  final repo = ref.watch(authRepositoryProvider);
  return await repo.userExists(username);
});

/// Provider to get user by username
final userByUsernameProvider = FutureProvider.family<Map<String, dynamic>?, String>(
  (ref, username) async {
    final repo = ref.watch(authRepositoryProvider);
    return await repo.getUserByUsername(username);
  },
);