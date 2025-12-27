import 'package:sqflite/sqflite.dart';
import 'package:voicesewa_client/features/auth/data/database/db_login.dart';

/// Data Access Object for user login operations
/// Handles all CRUD operations on user_login table
class DbLoginDao {

  final DbLogin _dbLogin = DbLogin();

  Future<Database> get _db async => await _dbLogin.database;

  /// Insert or update a user and set them as logged in
  /// All other users will be logged out
  Future<void> upsertUser({
    required String username,
    required String password,
    required int lastLoginAt,
  }) async {
    final db = await _db;

    // Start transaction to ensure atomicity
    await db.transaction((txn) async {
      // First, logout all users
      await txn.update(
        DbLogin.tableName,
        {DbLogin.columnIsLoggedIn: 0},
      );

      // Then insert/update the current user
      await txn.insert(
        DbLogin.tableName,
        {
          DbLogin.columnUsername: username,
          DbLogin.columnPassword: password,
          DbLogin.columnIsLoggedIn: 1,
          DbLogin.columnLastLoginAt: lastLoginAt,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  /// Get the currently logged-in user
  Future<Map<String, dynamic>?> getLoggedInUser() async {
    final db = await _db;
    final rows = await db.query(
      DbLogin.tableName,
      where: '${DbLogin.columnIsLoggedIn} = ?',
      whereArgs: [1],
      orderBy: '${DbLogin.columnLastLoginAt} DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  /// Get a user by username
  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    final db = await _db;
    final rows = await db.query(
      DbLogin.tableName,
      where: '${DbLogin.columnUsername} = ?',
      whereArgs: [username],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  /// Get all users (for debugging/admin purposes)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await _db;
    return await db.query(
      DbLogin.tableName,
      orderBy: '${DbLogin.columnLastLoginAt} DESC',
    );
  }

  /// Logout a specific user by username
  Future<int> logoutUser(String username) async {
    final db = await _db;
    return await db.update(
      DbLogin.tableName,
      {DbLogin.columnIsLoggedIn: 0},
      where: '${DbLogin.columnUsername} = ?',
      whereArgs: [username],
    );
  }

  /// Logout all users
  Future<int> logoutAllUsers() async {
    final db = await _db;
    return await db.update(
      DbLogin.tableName,
      {DbLogin.columnIsLoggedIn: 0},
    );
  }

  /// Update user password
  Future<int> updatePassword({
    required String username,
    required String newPassword,
  }) async {
    final db = await _db;
    return await db.update(
      DbLogin.tableName,
      {DbLogin.columnPassword: newPassword},
      where: '${DbLogin.columnUsername} = ?',
      whereArgs: [username],
    );
  }

  /// Update last login timestamp
  Future<int> updateLastLogin({
    required String username,
    required int lastLoginAt,
  }) async {
    final db = await _db;
    return await db.update(
      DbLogin.tableName,
      {DbLogin.columnLastLoginAt: lastLoginAt},
      where: '${DbLogin.columnUsername} = ?',
      whereArgs: [username],
    );
  }

  /// Delete a user by username
  Future<int> deleteUser(String username) async {
    final db = await _db;
    return await db.delete(
      DbLogin.tableName,
      where: '${DbLogin.columnUsername} = ?',
      whereArgs: [username],
    );
  }

  /// Delete all users (careful with this!)
  Future<int> deleteAllUsers() async {
    final db = await _db;
    return await db.delete(DbLogin.tableName);
  }

  /// Check if a user exists
  Future<bool> userExists(String username) async {
    final user = await getUserByUsername(username);
    return user != null;
  }

  /// Count total users
  Future<int> getUserCount() async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DbLogin.tableName}'
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}