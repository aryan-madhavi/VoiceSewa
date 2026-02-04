import 'package:sqflite/sqflite.dart';
import 'package:voicesewa_worker/core/database/tables/worker_pending_sync_table.dart';
import 'package:voicesewa_worker/features/sync/domain/worker_pending_sync_model.dart';

class WorkerPendingSyncDao {
  WorkerPendingSyncDao(this.db);

  final Database db;

  Future<void> enqueue(WorkerPendingSync item) {
    return db.insert(
      WorkerPendingSyncTable.table,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<WorkerPendingSync>> getPending({int limit = 50}) async {
    final rows = await db.query(
      WorkerPendingSyncTable.table,
      where: 'sync_status = ?',
      whereArgs: [WorkerSyncStatus.pending.index],
      orderBy: 'queued_at ASC, retry_count ASC',
      limit: limit,
    );
    return rows.map(WorkerPendingSync.fromMap).toList();
  }

  Future<List<WorkerPendingSync>> getSyncing() async {
    final rows = await db.query(
      WorkerPendingSyncTable.table,
      where: 'sync_status = ?',
      whereArgs: [WorkerSyncStatus.syncing.index],
      orderBy: 'queued_at ASC',
    );
    return rows.map(WorkerPendingSync.fromMap).toList();
  }

  Future<List<WorkerPendingSync>> getFailed() async {
    final rows = await db.query(
      WorkerPendingSyncTable.table,
      where: 'sync_status = ?',
      whereArgs: [WorkerSyncStatus.failed.index],
      orderBy: 'queued_at ASC',
    );
    return rows.map(WorkerPendingSync.fromMap).toList();
  }

  Future<int> getPendingCount() async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${WorkerPendingSyncTable.table} WHERE sync_status = ?',
      [WorkerSyncStatus.pending.index],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getSyncingCount() async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${WorkerPendingSyncTable.table} WHERE sync_status = ?',
      [WorkerSyncStatus.syncing.index],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getFailedCount() async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${WorkerPendingSyncTable.table} WHERE sync_status = ?',
      [WorkerSyncStatus.failed.index],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> updateStatus({
    required String id,
    required WorkerSyncStatus status,
    int? retryCount,
    String? lastError,
  }) {
    return db.update(
      WorkerPendingSyncTable.table,
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
    WorkerPendingSync item, {
    required String error,
  }) async {
    final nextRetry = item.retryCount + 1;

    if (nextRetry >= 5) {
      print('🔴 Max retries reached for ${item.entityId}, marking as failed');
      await db.update(
        WorkerPendingSyncTable.table,
        {
          'sync_status': WorkerSyncStatus.failed.index,
          'retry_count': nextRetry,
          'last_error': error,
        },
        where: 'id = ?',
        whereArgs: [item.id],
      );
    } else {
      print('🔄 Retry ${item.retryCount + 1}/5 for ${item.entityId}');
      await db.update(
        WorkerPendingSyncTable.table,
        {
          'sync_status': WorkerSyncStatus.pending.index,  // Reset to pending for retry
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
      WorkerPendingSyncTable.table,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Clear all sync items (useful for debugging/testing)
  Future<void> clearAll() {
    return db.delete(WorkerPendingSyncTable.table);
  }

  /// Reset all syncing items back to pending
  /// (Useful when app crashes during sync)
  Future<int> resetStuckSyncingItems() async {
    return await db.update(
      WorkerPendingSyncTable.table,
      {'sync_status': WorkerSyncStatus.pending.index},
      where: 'sync_status = ?',
      whereArgs: [WorkerSyncStatus.syncing.index],
    );
  }
}