class ServiceRequestTable {
  static const table = 'service_requests';

  static const createSql = '''
    CREATE TABLE IF NOT EXISTS $table(
      service_request_id TEXT PRIMARY KEY,
      client_id TEXT NOT NULL,
      worker_id TEXT,
      category TEXT NOT NULL,
      title TEXT NOT NULL,
      description TEXT,
      location TEXT,
      scheduled_at INTEGER,
      created_at INTEGER NOT NULL DEFAULT (strftime('%s','now')*1000),
      updated_at INTEGER NOT NULL DEFAULT (strftime('%s','now')*1000),
      status INTEGER NOT NULL
    );
  ''';

  static const indexesSql = [
    'CREATE INDEX IF NOT EXISTS idx_${table}_client ON $table(client_id);',
    'CREATE INDEX IF NOT EXISTS idx_${table}_worker ON $table(worker_id);',
    'CREATE INDEX IF NOT EXISTS idx_${table}_status ON $table(status);',
    'CREATE INDEX IF NOT EXISTS idx_${table}_updated_at ON $table(updated_at DESC);',
  ];
}
