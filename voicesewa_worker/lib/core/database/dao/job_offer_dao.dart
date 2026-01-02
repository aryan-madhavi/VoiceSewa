import 'package:sqflite/sqflite.dart';
import 'package:voicesewa_worker/core/database/tables/job_offer_table.dart';

class JobOfferDao {
  final Database db;

  JobOfferDao(this.db);

  /// Insert or update a job offer
  /// Sync is handled by SQL triggers automatically
  Future<int> upsert(JobOffer offer) {
    return db.insert(
      JobOfferTable.table,
      offer.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get a job offer by ID
  Future<JobOffer?> getById(String id) async {
    final rows = await db.query(
      JobOfferTable.table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return JobOffer.fromMap(rows.first);
  }

  /// Get job offers by status
  Future<List<JobOffer>> byStatus(JobOfferStatus status) async {
    final rows = await db.query(
      JobOfferTable.table,
      where: 'status = ?',
      whereArgs: [status.index],
      orderBy: 'created_at DESC',
    );
    return rows.map(JobOffer.fromMap).toList();
  }

  /// Get all job offers
  Future<List<JobOffer>> getAll({
    JobOfferStatus? status,
    String? clientId,
    int? limit,
    int? offset,
  }) async {
    final wheres = <String>[];
    final args = <Object?>[];

    if (status != null) {
      wheres.add('status = ?');
      args.add(status.index);
    }
    if (clientId != null) {
      wheres.add('client_id = ?');
      args.add(clientId);
    }

    final rows = await db.query(
      JobOfferTable.table,
      where: wheres.isEmpty ? null : wheres.join(' AND '),
      whereArgs: wheres.isEmpty ? null : args,
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    return rows.map(JobOffer.fromMap).toList();
  }

  /// Update job offer status
  Future<int> setStatus(String id, JobOfferStatus status) {
    return db.update(
      JobOfferTable.table,
      {'status': status.index},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete a job offer
  Future<int> delete(String id) {
    return db.delete(JobOfferTable.table, where: 'id = ?', whereArgs: [id]);
  }

  /// Get count by status
  Future<int> countByStatus(JobOfferStatus status) async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${JobOfferTable.table} WHERE status = ?',
      [status.index],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
