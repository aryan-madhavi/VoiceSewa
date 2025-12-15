import 'package:sqflite/sqflite.dart';

enum ServiceRequestStatus {
  pending,
  inProgress,
  completed,
  cancelled,
}

class ServiceRequest  {
  final String id;
  final String clientId;
  final String category;
  final String title;
  final String description;
  final String location;
  final int createdAt;
  final ServiceRequestStatus status;

  ServiceRequest({
    required this.id,
    required this.clientId,
    required this.category,
    required this.title,
    required this.description,
    required this.location,
    required this.createdAt,
    required this.status,
  });


  Map<String, Object?> toMap() => {
    'id': id,
    'client_id': clientId,
    'category': category,
    'title': title,
    'description': description,
    'location': location,
    'created_at': createdAt,
    'status': status.index,
  };

  static ServiceRequest fromMap(Map<String, Object?> m) => ServiceRequest(
    id: m['id'] as String,
    clientId: m['client_id'] as String,
    category: m['category'] as String,
    title: m['title'] as String,
    description: m['description'] as String,
    location: m['location'] as String,
    createdAt: m['created_at'] as int,
    status: ServiceRequestStatus.values[m['status'] as int],
  );

}


class ServiceRequestTable {
  static const table = 'service_requests';
  static const createSql = '''
  CREATE TABLE IF NOT EXISTS $table(
    id TEXT PRIMARY KEY,
    client_id TEXT NOT NULL,
    category TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    location TEXT,
    created_at INTEGER NOT NULL,
    status INTEGER NOT NULL
  );
  ''';

  final Database db;
  ServiceRequestTable(this.db);

  Future<int> upsert(ServiceRequest s) =>
      db.insert(table, s.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

  Future<List<ServiceRequest>> all({ServiceRequestStatus? status}) async {
    final rows = await db.query(table,
        where: status == null ? null : 'status=?',
        whereArgs: status == null ? null : [status.index],
        orderBy: 'created_at DESC');
    return rows.map(ServiceRequest.fromMap).toList();
  }

  Future<int> setStatus(String id, ServiceRequestStatus s) =>
      db.update(table, {'status': s.index}, where: 'id=?', whereArgs: [id]);

  Future<int> delete(String id) => db.delete(table, where: 'id=?', whereArgs: [id]);
}

