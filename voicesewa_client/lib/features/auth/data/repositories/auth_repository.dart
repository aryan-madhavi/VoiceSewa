import 'package:voicesewa_client/features/auth/data/daos/db_login_dao.dart';

/// Repository for authentication operations
/// Sits above DAO layer and handles business logic
class AuthRepository {
  final DbLoginDao _dao;

  AuthRepository(this._dao);

  /// Login user - stores credentials and marks as logged in
  Future<void> login({
    required String username,
    required String password,
  }) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    await _dao.upsertUser(
      username: username,
      password: password,
      lastLoginAt: now,
    );
  }

  /// Get currently logged-in user
  Future<Map<String, dynamic>?> getLoggedInUser() async {
    return await _dao.getLoggedInUser();
  }

  /// Check if user session is still valid (within specified days)
  Future<bool> isSessionValid({int days = 5}) async {
    final user = await _dao.getLoggedInUser();
    if (user == null) return false;

    final lastLoginAt = user['last_login_at'] as int;
    final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    final secondsElapsed = now - lastLoginAt;
    final maxSeconds = days * 24 * 60 * 60;

    return secondsElapsed <= maxSeconds;
  }

  /// Logout user by username
  Future<void> logout(String username) async {
    await _dao.logoutUser(username);
  }

  /// Logout all users
  Future<void> logoutAll() async {
    await _dao.logoutAllUsers();
  }

  /// Update user password
  Future<void> updatePassword({
    required String username,
    required String newPassword,
  }) async {
    await _dao.updatePassword(
      username: username,
      newPassword: newPassword,
    );
  }

  /// Refresh user's last login timestamp
  Future<void> refreshSession(String username) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    await _dao.updateLastLogin(
      username: username,
      lastLoginAt: now,
    );
  }

  /// Check if user exists in database
  Future<bool> userExists(String username) async {
    return await _dao.userExists(username);
  }

  /// Get user details by username
  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    return await _dao.getUserByUsername(username);
  }

  /// Get total registered users count
  Future<int> getTotalUsers() async {
    return await _dao.getUserCount();
  }
}