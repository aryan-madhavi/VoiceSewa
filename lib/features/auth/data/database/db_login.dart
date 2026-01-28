import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Database management for user login/session tracking
/// Handles database initialization and table creation only
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

  /// Close database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}