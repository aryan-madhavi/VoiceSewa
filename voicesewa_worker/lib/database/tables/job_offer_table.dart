import 'package:sqflite/sqflite.dart';

enum JobOfferStatus { newOffer, seen, declined, accepted }

class JobOffer {
  final String id;
  final String clientId;
  final String title;
  final String description;
  final String location;  
  final int createdAt;
  final JobOfferStatus status;

  JobOffer({
    required this.id,
    required this.clientId,
    required this.title,
    required this.description,
    required this.location,
    required this.createdAt,
    required this.status,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'client_id': clientId,
    'title': title,
    'description': description,
    'location': location,
    'created_at': createdAt,
    'status': status.index,
  };

  static JobOffer fromMap(Map<String, Object?> m) => JobOffer(
    id: m['id'] as String,
    clientId: m['client_id'] as String,
    title: m['title'] as String,
    description: m['description'] as String,
    location: m['location'] as String,
    createdAt: m['created_at'] as int,
    status: JobOfferStatus.values[m['status'] as int],
  );
}

class JobOfferTable {
  static const table = 'job_offers';
  static const createSql = '''
  CREATE TABLE IF NOT EXISTS $table(
    id TEXT PRIMARY KEY,
    client_id TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    location TEXT,
    created_at INTEGER NOT NULL,
    status INTEGER NOT NULL
  );
  ''';

  final Database db;
  JobOfferTable(this.db);

  Future<int> upsert(JobOffer j) => db.insert(table, j.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace);

  Future<List<JobOffer>> byStatus(JobOfferStatus s) async {
    final rows = await db.query(table, where: 'status=?', whereArgs: [s.index], orderBy: 'created_at DESC');
    return rows.map(JobOffer.fromMap).toList();
  }

  Future<int> setStatus(String id, JobOfferStatus s) =>
      db.update(table, {'status': s.index}, where: 'id=?', whereArgs: [id]);

  Future<int> delete(String id) => db.delete(table, where: 'id=?', whereArgs: [id]);
}
