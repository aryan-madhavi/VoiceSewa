import 'dart:async';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:voicesewa_client/core/database/tables/client_profile_table.dart';
import 'tables/service_request_table.dart';
import 'tables/client_pending_sync_table.dart';
import 'SyncService/pending_sync_helper_trigger.dart';

/// User-specific database manager
/// Each user gets their own isolated database file
class ClientDatabase {
  static const _dbversion = 1;
  
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

  /// Get database for current user
  Future<Database> get database async {
    if (_db != null) return _db!;

    if (_currentUserId == null) {
      throw StateError('No user logged in');
    }

    final dir = await getApplicationDocumentsDirectory();
    // Create user-specific database name: email@example.com_voicesewa_client.db
    final dbName = '${_currentUserId}_voicesewa_client.db';
    final path = join(dir.path, dbName);
    
    _db = await openDatabase(
      path,
      version: _dbversion,
      onCreate: _onCreate,
    );

    return _db!;
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
    await installServiceRequestSyncTriggers(db);

    // Create additional indexes
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
    final instance = _instances[userId];
    if (instance?._db != null) {
      await instance!._db!.close();
      instance._db = null;
    }
    _instances.remove(userId);
    
    // Clear current user if it matches
    if (_currentUserId == userId) {
      _currentUserId = null;
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
      final dbName = '${userId}_voicesewa_client.db';
      final path = join(dir.path, dbName);
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