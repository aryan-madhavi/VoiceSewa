import 'package:sqflite/sqflite.dart';
import 'package:voicesewa_client/core/database/tables/client_profile_table.dart';
import 'package:voicesewa_client/features/auth/domain/client_model.dart';

class ClientProfileDao {
  final Database db;

  ClientProfileDao(this.db);

  /// Insert or update a client profile
  Future<int> upsert(ClientProfile profile) {
    return db.insert(
      ClientProfileTable.table,
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get a client profile by clientId
  Future<ClientProfile?> get(String clientId) async {
    final rows = await db.query(
      ClientProfileTable.table,
      where: 'client_id = ?',
      whereArgs: [clientId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ClientProfile.fromMap(rows.first);
  }

  /// Optional: get all clients
  Future<List<ClientProfile>> getAll() async {
    final rows = await db.query(ClientProfileTable.table);
    return rows.map(ClientProfile.fromMap).toList();
  }

  /// Optional: delete a client
  Future<int> delete(String clientId) {
    return db.delete(
      ClientProfileTable.table,
      where: 'client_id = ?',
      whereArgs: [clientId],
    );
  }
}
