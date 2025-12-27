import 'dart:async';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'tables/client_profile_table.dart';
import 'tables/service_request_table.dart';
import 'tables/client_pending_sync_table.dart';
//import 'package:voicesewa_client/features/sync/data/pending_sync_helper_trigger.dart';

/// User-specific database manager
/// Each user gets their own isolated database file
class ClientDatabase {
  static const _dbVersion = 1;

  // Store instances per user (userId -> ClientDatabase)
  static final Map<String, ClientDatabase> _instances = {};
  static String? _currentUserId;

  Database? _db;

  ClientDatabase._();

  /// Get database instance for specific user
  /// Call this when user logs in
  static ClientDatabase instanceForUser(String userId) {
    _currentUserId = userId;
    if (!_instances.containsKey(userId)) {
      _instances[userId] = ClientDatabase._();
    }
    return _instances[userId]!;
  }

  /// Get current user's database instance
  /// Throws error if no user is logged in
  static ClientDatabase get instance {
    if (_currentUserId == null) {
      throw StateError('No user logged in. Call instanceForUser(userId) first.');
    }
    return instanceForUser(_currentUserId!);
  }

  Future<Database> get database async {
    if (_currentUserId == null) {
      throw StateError('No user logged in');
    }

    // Check if current database instance is valid
    if (_db != null) {
      try {
        // Verify database is actually open and working
        await _db!.rawQuery('SELECT 1');
        return _db!;
      } catch (e) {
        print('⚠️ Database instance invalid: $e');
        _db = null; // Clear invalid instance
      }
      return _db!;
    }

    _db = await _openDatabase();

    print('✅ Database opened successfully');
    return _db!;
  }

  Future<Database> _openDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final _dbName = '${_currentUserId}_voicesewa_client.db';
    final path = join(dir.path, _dbName);

    print('📂 Opening database at: $path');

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create all tables for user database
  Future<void> _onCreate(Database db, int version) async {
    // Create tables
    await db.execute(ClientProfileTable.createSql);
    await db.execute(ServiceRequestTable.createSql);
    await db.execute(ClientPendingSyncTable.createSql);

    // Create indexes for service requests
    for (final sql in ServiceRequestTable.indexesSql) {
      await db.execute(sql);
    }

    // Install sync triggers
    //await installServiceRequestSyncTriggers(db);

    // Create additional indexes
    await _createIndexes(db);
  }

  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Future-proofing:
    // if (oldVersion < 2) { ... }
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sr_status ON service_requests(status);',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_csync_status ON client_pending_sync(sync_status);',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_pending_retry ON client_pending_sync(queued_at, retry_count);',
    );
  }

  /// Close and cleanup user database
  /// Call this when user logs out
  static Future<void> closeUserDatabase(String userId) async {
    print('🔒 Closing database for user: $userId');
    final instance = _instances[userId];
    if (instance?._db != null) {
      await instance!._db!.close();
      instance._db = null;
      print('✅ Database closed for $userId');
    }
    _instances.remove(userId);
    
    if (_currentUserId == userId) {
      _currentUserId = null;
      print('🚪 Current user cleared');
    }
  }

  /// Delete user database file permanently
  /// WARNING: This deletes all user data!
  static Future<void> deleteUserDatabase(String userId) async {
    // Close database first
    await closeUserDatabase(userId);
    
    // Delete database file
    try {
      final dir = await getApplicationDocumentsDirectory();
      final _dbName = '${userId}_voicesewa_client.db';
      final path = join(dir.path, _dbName);
      await deleteDatabase(path);
    } catch (e) {
      print('Error deleting database for $userId: $e');
    }
  }

  /// Get current logged-in user ID
  static String? get currentUserId => _currentUserId;

  /// Check if user has a database
  static Future<bool> userDatabaseExists(String userId) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final dbName = '${userId}_voicesewa_client.db';
      final path = join(dir.path, dbName);
      return await databaseExists(path);
    } catch (e) {
      return false;
    }
  }
}