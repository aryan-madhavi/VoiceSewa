import 'dart:async';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'tables/worker_profile_table.dart';
import 'tables/job_offer_table.dart';
import 'tables/booking_table.dart';
import 'tables/worker_pending_sync_table.dart';
import '../../features/sync/data/sync_triggers.dart';

/// User-specific database manager for Worker app
/// Each user gets their own isolated database file
class WorkerDatabase {
  static const _dbVersion = 1; // Bumped from 1 to 2 for trigger fix

  // Store instances per user (userId -> WorkerDatabase)
  static final Map<String, WorkerDatabase> _instances = {};
  static String? _currentUserId;

  Database? _db;

  WorkerDatabase._();

  /// Get database instance for specific user
  /// Call this when user logs in
  static WorkerDatabase instanceForUser(String userId) {
    _currentUserId = userId;
    if (!_instances.containsKey(userId)) {
      _instances[userId] = WorkerDatabase._();
    }
    return _instances[userId]!;
  }

  /// Get current user's database instance
  /// Throws error if no user is logged in
  static WorkerDatabase get instance {
    if (_currentUserId == null) {
      throw StateError(
        'No user logged in. Call instanceForUser(userId) first.',
      );
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
    }

    _db = await _openDatabase();

    print('✅ Database opened successfully');
    return _db!;
  }

  Future<Database> _openDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final _dbName = '${_currentUserId}_voicesewa_worker.db';
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
    print('🔧 Creating database tables...');

    // Create tables
    await db.execute(WorkerProfileTable.createSql);
    await db.execute(JobOfferTable.createSql);
    await db.execute(BookingTable.createSql);
    await db.execute(WorkerPendingSyncTable.createSql);

    // Install sync triggers
    await installWorkerSyncTriggers(db);

    // Create additional indexes
    await _createIndexes(db);

    print('✅ Database tables created');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('🔄 Upgrading database from v$oldVersion to v$newVersion');

    // Upgrade from version 1 to 2: Fix json_object triggers
    if (oldVersion < 2) {
      print('🔧 Fixing triggers (removing json_object dependency)...');

      // Reinstall triggers with compatible version
      await installWorkerSyncTriggers(db);

      print('✅ Triggers upgraded successfully');
    }

    print('✅ Database upgrade complete');
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_booking_status ON bookings(status);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_booking_worker ON bookings(worker_id);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_job_offer_status ON job_offers(status);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sync_status ON worker_pending_sync(sync_status);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_pending_retry ON worker_pending_sync(queued_at, retry_count);',
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
      final _dbName = '${userId}_voicesewa_worker.db';
      final path = join(dir.path, _dbName);
      await deleteDatabase(path);
      print('🗑️ Database deleted for $userId');
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
      final dbName = '${userId}_voicesewa_worker.db';
      final path = join(dir.path, dbName);
      return await databaseExists(path);
    } catch (e) {
      return false;
    }
  }
}
