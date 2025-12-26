import 'package:sqflite/sqflite.dart';
import 'package:voicesewa_client/core/database/tables/client_pending_sync_table.dart';
import 'package:voicesewa_client/features/sync/domain/client_pending_sync_model.dart';

class ClientPendingSyncDao {
  ClientPendingSyncDao(this.db);

  final Database db;

  Future<void> enqueue(ClientPendingSync item) {
    return db.insert(
      ClientPendingSyncTable.table,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ClientPendingSync>> getPending({int limit = 50}) async {
    final rows = await db.query(
      ClientPendingSyncTable.table,
      where: 'sync_status = ?',
      whereArgs: [ClientSyncStatus.pending.index],
      orderBy: 'queued_at ASC, retry_count ASC',
      limit: limit,
    );
    return rows.map(ClientPendingSync.fromMap).toList();
  }

  Future<List<ClientPendingSync>> getFailed() async {
    final rows = await db.query(
      ClientPendingSyncTable.table,
      where: 'sync_status = ?',
      whereArgs: [ClientSyncStatus.failed.index],
      orderBy: 'queued_at ASC',
    );
    return rows.map(ClientPendingSync.fromMap).toList();
  }

  Future<int> getPendingCount() async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${ClientPendingSyncTable.table} WHERE sync_status = ?',
      [ClientSyncStatus.pending.index],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getFailedCount() async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${ClientPendingSyncTable.table} WHERE sync_status = ?',
      [ClientSyncStatus.failed.index],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> updateStatus({
    required String id,
    required ClientSyncStatus status,
    int? retryCount,
    String? lastError,
  }) {
    return db.update(
      ClientPendingSyncTable.table,
      {
        'sync_status': status.index,
        if (retryCount != null) 'retry_count': retryCount,
        if (lastError != null) 'last_error': lastError,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markFailed(
    ClientPendingSync item, {
    required String error,
  }) async {
    final nextRetry = item.retryCount + 1;
  
    if (nextRetry >= 5) {
      await db.update(
        ClientPendingSyncTable.table,
        {
          'sync_status': ClientSyncStatus.failed.index,
          'retry_count': nextRetry,
          'last_error': error,
        },
        where: 'id = ?',
        whereArgs: [item.id],
      );
    } else {
      await db.update(
        ClientPendingSyncTable.table,
        {
          'retry_count': nextRetry,
          'last_error': error,
        },
        where: 'id = ?',
        whereArgs: [item.id],
      );
    }
  }

  Future<void> delete(String id) {
    return db.delete(
      ClientPendingSyncTable.table,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}