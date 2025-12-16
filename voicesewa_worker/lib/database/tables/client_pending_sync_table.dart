import 'package:sqflite/sqflite.dart';

enum ClientSyncStatus {
  pending,
  syncing,
  completed,
  failed,
}

class ClientPendingSync {
  final String id;
  final String entity;
  final String action;
  final String payload;
  final int createdAt;
  final ClientSyncStatus syncStatus;
  final int retryCount;

  ClientPendingSync({
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

  static ClientPendingSync fromMap(Map<String, Object?> m) => ClientPendingSync(
    id: m['id'] as String,
    entity: m['entity'] as String,
    action: m['action'] as String,
    payload: m['payload'] as String,
    createdAt: m['created_at'] as int,
    syncStatus: ClientSyncStatus.values[m['sync_status'] as int],
    retryCount: m['retry_count'] as int,
  );
  
}

class ClientPendingSyncTable {
    
  static const table = 'client_pending_sync';
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
  ClientPendingSyncTable(this.db);

  Future<int> enqueue(ClientPendingSync op) =>
      db.insert(table, op.toMap(), conflictAlgorithm: ConflictAlgorithm.abort);

  Future<List<ClientPendingSync>> pending({int limit = 50}) async {
    final rows = await db.query(table,
        where: 'sync_status=?', whereArgs: [ClientSyncStatus.pending.index],
        orderBy: 'created_at ASC', limit: limit);
    return rows.map(ClientPendingSync.fromMap).toList();
  }

  Future<int> mark(String id, ClientSyncStatus status, {int? retryCount}) =>
      db.update(table, {
        'sync_status': status.index,
        if (retryCount != null) 'retry_count': retryCount,
      }, where: 'id=?', whereArgs: [id]);
}

