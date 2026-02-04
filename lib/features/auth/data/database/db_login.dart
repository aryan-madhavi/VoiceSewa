import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:voicesewa_worker/features/auth/data/database/db_login_dao.dart';

/// Database management for user login/session tracking
/// Handles database initialization and provides access to DAO operations
class DbLogin {
  static final DbLogin _instance = DbLogin._internal();
  factory DbLogin() => _instance;
  DbLogin._internal();

  static Database? _database;
  static const String _dbName = 'current_user_login.db';
  static const int _dbVersion = 1;

  /// Table and column names
  static const String tableName = 'user_login';
  static const String columnId = 'id';
  static const String columnUsername = 'username';
  static const String columnPassword = 'password';
  static const String columnIsLoggedIn = 'is_logged_in';
  static const String columnLastLoginAt = 'last_login_at';

  // DAO instance for operations
  DbLoginDao? _dao;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  /// Create user_login table
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName(
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnUsername TEXT NOT NULL UNIQUE,
        $columnPassword TEXT NOT NULL,
        $columnIsLoggedIn INTEGER NOT NULL DEFAULT 0,
        $columnLastLoginAt INTEGER NOT NULL
      )
    ''');

    // Create index for faster lookups
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_username 
      ON $tableName($columnUsername)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_is_logged_in 
      ON $tableName($columnIsLoggedIn)
    ''');
  }

  // ============================================================
  // CONVENIENCE METHODS - Delegate to DAO
  // ============================================================

  /// Get DAO instance
  Future<DbLoginDao> get dao async {
    if (_dao != null) return _dao!;
    await database; // Ensure DB is initialized
    _dao = DbLoginDao();
    return _dao!;
  }

  /// Set logged in user - saves session
  Future<void> setLoggedInUser({
    required String username,
    required String password,
  }) async {
    final loginDao = await dao;
    await loginDao.upsertUser(
      username: username,
      password: password,
      lastLoginAt: DateTime.now().millisecondsSinceEpoch,
    );
    print('✅ Session saved for: $username');
  }

  /// Get currently logged in user
  Future<Map<String, dynamic>?> getLoggedInUser() async {
    final loginDao = await dao;
    return await loginDao.getLoggedInUser();
  }

  /// Check if session is valid (logged in within last 30 days)
  Future<bool> isSessionValid() async {
    final user = await getLoggedInUser();
    if (user == null) return false;

    final lastLogin = user[columnLastLoginAt] as int;
    final now = DateTime.now().millisecondsSinceEpoch;
    final thirtyDays = 30 * 24 * 60 * 60 * 1000; // 30 days in milliseconds

    return (now - lastLogin) < thirtyDays;
  }

  /// Logout user
  Future<void> logoutUser(String username) async {
    final loginDao = await dao;
    await loginDao.logoutUser(username);
    print('🚪 Logged out: $username');
  }

  /// Close database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _dao = null;
    }
  }
}