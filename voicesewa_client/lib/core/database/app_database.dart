import 'dart:async';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'tables/client_profile_table.dart';
import 'tables/service_request_table.dart';
import 'tables/client_pending_sync_table.dart';

class AppDatabase {
  static const _dbName = 'voicesewa_client.db';
  static const _dbVersion = 1;

  AppDatabase._internal();
  static final AppDatabase instance = AppDatabase._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(ClientProfileTable.createSql);
    await db.execute(ServiceRequestTable.createSql);
    await db.execute(ClientPendingSyncTable.createSql);

    for (final sql in ServiceRequestTable.indexesSql) {
      await db.execute(sql);
    }

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
}