import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbLoginDao {
  static final DbLoginDao _instance = DbLoginDao._internal();
  factory DbLoginDao() => _instance;
  DbLoginDao._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'current_user_login.db');
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

  // Insert or update a logged-in user
  Future<void> upsertUser({
    required String username,
    required String password,
    required int lastLoginAt,
  }) async {
    final db = await database;
    await db.update('user_login', {'is_logged_in': 0});
    await db.insert(
      'user_login',
      {
        'username': username,
        'password': password,
        'is_logged_in': 1,
        'last_login_at': lastLoginAt,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

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
