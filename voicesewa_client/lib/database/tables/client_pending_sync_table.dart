import 'package:sqflite/sqflite.dart';

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
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'entity_type': entityType,
    'entity_id': entityId,
    'action': action,
    'payload': payload,
    'queued_at': queuedAt,
    'last_error': lastError,
    'sync_status': syncStatus.index,
    'retry_count': retryCount,
  };

  static ClientPendingSync fromMap(Map<String, Object?> m) => ClientPendingSync(
    id: m['id'] as String,
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
  ''';

  final Database db;
  ClientPendingSyncTable(this.db);

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
