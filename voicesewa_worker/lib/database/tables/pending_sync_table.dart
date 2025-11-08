import 'package:sqflite/sqflite.dart';

enum SyncStatus { pending, syncing, done, failed }

class PendingSync {
  final String id;        
  final String entity;    
  final String action;   
  final String payload;   
  final int createdAt;
  final SyncStatus syncStatus;
  final int retryCount;

  PendingSync({
    required this.id,
    required this.entity,
    required this.action,
    required this.payload,
    required this.createdAt,
    required this.syncStatus,
    required this.retryCount,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'entity': entity,
    'action': action,
    'payload': payload,
    'created_at': createdAt,
    'sync_status': syncStatus.index,
    'retry_count': retryCount,
  };

  static PendingSync fromMap(Map<String, Object?> m) => PendingSync(
    id: m['id'] as String,
    entity: m['entity'] as String,
    action: m['action'] as String,
    payload: m['payload'] as String,
    createdAt: m['created_at'] as int,
    syncStatus: SyncStatus.values[m['sync_status'] as int],
    retryCount: m['retry_count'] as int,
  );
}

class PendingSyncTable {
  static const table = 'pending_sync';
  static const createSql = '''
  CREATE TABLE IF NOT EXISTS $table(
    id TEXT PRIMARY KEY,
    entity TEXT NOT NULL,
    action TEXT NOT NULL,
    payload TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    sync_status INTEGER NOT NULL DEFAULT 0,
    retry_count INTEGER NOT NULL DEFAULT 0
  );
  ''';

  final Database db;
  PendingSyncTable(this.db);

  Future<int> enqueue(PendingSync op) =>
      db.insert(table, op.toMap(), conflictAlgorithm: ConflictAlgorithm.abort);

  Future<List<PendingSync>> pending({int limit = 50}) async {
    final rows = await db.query(table,
        where: 'sync_status=?', whereArgs: [SyncStatus.pending.index],
        orderBy: 'created_at ASC', limit: limit);
    return rows.map(PendingSync.fromMap).toList();
  }

  Future<int> mark(String id, SyncStatus status, {int? retryCount}) =>
      db.update(table, {
        'sync_status': status.index,
        if (retryCount != null) 'retry_count': retryCount,
      }, where: 'id=?', whereArgs: [id]);

  Future<int> purgeDone({int olderThanMs = 7 * 24 * 3600 * 1000}) async {
    final cutoff = DateTime.now().millisecondsSinceEpoch - olderThanMs;
    return db.delete(table,
        where: 'sync_status=? AND created_at<?',
        whereArgs: [SyncStatus.done.index, cutoff]);
  }
}
