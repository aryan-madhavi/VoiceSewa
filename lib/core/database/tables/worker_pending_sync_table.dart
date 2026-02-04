class WorkerPendingSyncTable {
  static const table = 'worker_pending_sync';

  static const createSql = '''
    CREATE TABLE IF NOT EXISTS $table(
      id TEXT PRIMARY KEY,
      entity_type TEXT NOT NULL,
      entity_id TEXT NOT NULL,
      action TEXT NOT NULL,
      payload TEXT,
      queued_at INTEGER NOT NULL,
      retry_count INTEGER DEFAULT 0,
      last_error TEXT,
      sync_status INTEGER NOT NULL
    );
  ''';
}