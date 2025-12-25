import 'package:sqflite/sqflite.dart';

<<<<<<< HEAD:voicesewa_worker/lib/database/tables/client_pending_sync_table.dart
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
=======
enum ClientSyncStatus { pending, syncing, completed, failed }

class ClientPendingSync {
  final String id;
  final String entityType;
  final String entityId;
  final String action;
  final String payload;
  final int queuedAt;
  final int? retryCount;
  final String? lastError;
  final ClientSyncStatus syncStatus;

  ClientPendingSync({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.payload,
    required this.queuedAt,
    this.retryCount,
    this.lastError,
    this.syncStatus = ClientSyncStatus.pending,
>>>>>>> auth/firebase:voicesewa_client/lib/database/tables/client_pending_sync_table.dart
  });

  Map<String, Object?> toMap() => {
    'id': id,
<<<<<<< HEAD:voicesewa_worker/lib/database/tables/client_pending_sync_table.dart
    'entity': entity,
    'action': action,
    'payload': payload,
    'created_at': createdAt,
=======
    'entity_type': entityType,
    'entity_id': entityId,
    'action': action,
    'payload': payload,
    'queued_at': queuedAt,
    'last_error': lastError,
>>>>>>> auth/firebase:voicesewa_client/lib/database/tables/client_pending_sync_table.dart
    'sync_status': syncStatus.index,
    'retry_count': retryCount,
  };

  static ClientPendingSync fromMap(Map<String, Object?> m) => ClientPendingSync(
    id: m['id'] as String,
<<<<<<< HEAD:voicesewa_worker/lib/database/tables/client_pending_sync_table.dart
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
=======
    entityType: m['entity_type'] as String,
    entityId: m['entity_id'] as String,
    action: m['action'] as String,
    payload: m['payload'] as String,
    queuedAt: m['queued_at'] as int,
    retryCount: m['retry_count'] as int,
    lastError: m['last_error'] as String,
    syncStatus: ClientSyncStatus.values[m['sync_status'] as int],
  );
}

class ClientPendingSyncTable {
  static const table = 'client_pending_sync';
  static const createSql =
      '''
    CREATE TABLE IF NOT EXISTS $table(
      id TEXT PRIMARY KEY,
      entity_type TEXT NOT NULL,
      entity_id TEXT NOT NULL,
      action TEXT NOT NULL,
      payload TEXT,
      queued_at INTEGER,
      retry_count INTEGER DEFAULT 0,
      last_error TEXT,
      sync_status INTEGER NOT NULL
    );
>>>>>>> auth/firebase:voicesewa_client/lib/database/tables/client_pending_sync_table.dart
  ''';

  final Database db;
  ClientPendingSyncTable(this.db);

<<<<<<< HEAD:voicesewa_worker/lib/database/tables/client_pending_sync_table.dart
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

=======
  Future<void> enqueue({
    required String id,
    required String entityType,
    required String entityId,
    required String action,
    String? payload,
    int? queuedAt,
  }) {
    return db.insert(
      table, 
      {
        'id': id,
        'entity_type': entityType,
        'entity_id': entityId,
        'action': action,
        'payload': payload ?? '',
        'queued_at': queuedAt ?? DateTime.now().millisecondsSinceEpoch,
        'retry_count': 0,
        'last_error': null,
        'sync_status': ClientSyncStatus.pending.index,
      },
     conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
>>>>>>> auth/firebase:voicesewa_client/lib/database/tables/client_pending_sync_table.dart
