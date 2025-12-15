import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbLogin {

  static final DbLogin _instance = DbLogin._internal();
  factory DbLogin() => _instance;
  DbLogin._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'current_user_login.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_login(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        password TEXT NOT NULL,
        is_logged_in INTEGER NOT NULL DEFAULT 0,
        last_login_at INTEGER NOT NULL
      )
    ''');
  }

 /// Set ONE user as logged in, others logged out
  Future<void> setLoggedInUser({
    required String username,
    required String password,
  }) async {
    final db = await database;
    final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;

    // logout all users first
    await db.update('user_login', {'is_logged_in': 0});

    // upsert user
    await db.insert(
      'user_login',
      {
        'username': username, 
        'password': password,
        'is_logged_in': 1,
        'last_login_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  /// Get the single user who is logged in
  Future<Map<String, dynamic>?> getLoggedInUser() async {
    final db = await database;
    final rows = await db.query(
      'user_login',
      where: 'is_logged_in = 1',
      orderBy: 'last_login_at DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  /// Determines if logged-in user's session is still valid
  Future<bool> isSessionValid({int days = 5}) async {
    final u = await getLoggedInUser();
    if (u == null) return false;
    final last = u['last_login_at'] as int;
    final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    return (now - last) <= days * 24 * 60 * 60;
  }

  /// Logout a user by username
  Future<void> logoutUser(String username) async {
    final db = await database;
    await db.update(
      'user_login',
      {'is_logged_in': 0},
      where: 'username = ?',
      whereArgs: [username],
    );
  }

}