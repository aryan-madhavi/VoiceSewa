import 'package:sqflite/sqflite.dart';
import 'package:voicesewa_worker/core/database/tables/worker_profile_table.dart';

class WorkerProfileDao {
  final Database db;

  WorkerProfileDao(this.db);

  /// Insert or update a worker profile
  /// Sync is handled by SQL triggers automatically
  Future<int> upsert(WorkerProfile profile) {
    return db.insert(
      WorkerProfileTable.table,
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get a worker profile by workerId
  Future<WorkerProfile?> get(String workerId) async {
    final rows = await db.query(
      WorkerProfileTable.table,
      where: 'worker_id = ?',
      whereArgs: [workerId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return WorkerProfile.fromMap(rows.first);
  }

  /// Get all worker profiles
  Future<List<WorkerProfile>> getAll() async {
    final rows = await db.query(
      WorkerProfileTable.table,
      orderBy: 'updated_at DESC',
    );
    return rows.map(WorkerProfile.fromMap).toList();
  }

  /// Delete a worker profile
  Future<int> delete(String workerId) {
    return db.delete(
      WorkerProfileTable.table,
      where: 'worker_id = ?',
      whereArgs: [workerId],
    );
  }

  /// Update specific fields
  Future<int> updateFields(String workerId, Map<String, dynamic> fields) {
    fields['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    return db.update(
      WorkerProfileTable.table,
      fields,
      where: 'worker_id = ?',
      whereArgs: [workerId],
    );
  }
}