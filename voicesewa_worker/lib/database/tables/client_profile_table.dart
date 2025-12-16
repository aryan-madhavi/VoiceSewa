import 'package:sqflite/sqflite.dart';  

class ClientProfile {
  final String clientId;
  final String name;
  final String phone;
  final String language;
  final String? address;
  final int updatedAt;

  ClientProfile({
    required this.clientId,
    required this.name,
    required this.phone,
    required this.language,
    this.address,
    required this.updatedAt,
  });


  Map<String, Object?> toMap() => {
    'client_id': clientId,
    'name': name,
    'phone': phone,
    'language': language,
    'address': address,
    'updated_at': updatedAt,
  };

  static ClientProfile fromMap(Map<String, Object?> m) => ClientProfile(
    clientId: m['client_id'] as String,
    name: m['name'] as String,
    phone: m['phone'] as String,
    language: m['language'] as String,
    address: m['address'] as String?,
    updatedAt: m['updated_at'] as int,
  );

}

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

   final Database db;
  ClientProfileTable(this.db);

  Future<int> upsert(ClientProfile p) =>
      db.insert(table, p.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

  Future<ClientProfile?> get(String clientId) async {
    final rows = await db.query(table, where: 'client_id=?', whereArgs: [clientId], limit: 1);
    if (rows.isEmpty) return null;
    return ClientProfile.fromMap(rows.first);
  }

}