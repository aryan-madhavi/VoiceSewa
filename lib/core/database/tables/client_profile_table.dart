class ClientProfileTable {
  static const table = 'client_profile';

  static const createSql = '''
    CREATE TABLE IF NOT EXISTS $table (
      client_id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      phone TEXT NOT NULL,
      language TEXT NOT NULL,
      address TEXT,
      updated_at INTEGER NOT NULL
    );
  ''';
}