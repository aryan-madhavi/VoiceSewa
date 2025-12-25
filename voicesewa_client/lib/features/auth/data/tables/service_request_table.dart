import 'package:sqflite/sqflite.dart';

enum ServiceStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled,
}

class ServiceRequest  {
  final String serviceRequestId;
  final String clientId;
  final String? workerId;
  final String category;
  final String title;
  final String? description;
  final String? location;
  final int? scheduledAt;
  final int? createdAt;
  final int? updatedAt;  
  final ServiceStatus status;
  

  ServiceRequest({
    required this.serviceRequestId,
    required this.clientId,
    required this.workerId,
    required this.category,
    required this.title,
    required this.description,
    required this.location,
    required this.scheduledAt,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
  });


  Map<String, Object?> toMap() => {
    'service_request_id': serviceRequestId,
    'client_id': clientId,
    'worker_id': workerId,
    'category': category,
    'title': title,
    'description': description,
    'location': location,
    'scheduled_at': scheduledAt,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'status': status.index,
  };

  static ServiceRequest fromMap(Map<String, Object?> m) {
    final si = (m['status'] as int?) ?? 0;
    final statusSafe = si >= 0 && si < ServiceStatus.values.length ? si : 0;

    return ServiceRequest(
      serviceRequestId: m['service_request_id'] as String,
      clientId: m['client_id'] as String,
      workerId: m['worker_id'] as String?,
      category: m['category'] as String,
      title: m['title'] as String,
      description: m['description'] as String?,
      location: m['location'] as String?,
      scheduledAt: m['scheduled_at'] as int?,
      createdAt: m['created_at'] as int?,
      updatedAt: m['updated_at'] as int?,
      status: ServiceStatus.values[statusSafe],
    );
  }

}


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

  final Database db;
  ServiceRequestTable(this.db);

  Future<int> upsert(ServiceRequest s) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final map = s.toMap();

    // If timestamps are null, supply defaults here; DB also has defaults.
    map['created_at'] ??= now;
    map['updated_at'] ??= now;

    return db.insert(
      table,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }


 Future<List<ServiceRequest>> all({
    ServiceStatus? status,
    String? clientId,
    String? workerId,
    String? searchTitle,
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
    if (workerId != null) {
      wheres.add('worker_id = ?');
      args.add(workerId);
    }
    if (searchTitle != null && searchTitle.trim().isNotEmpty) {
      wheres.add('title LIKE ?');
      args.add('%$searchTitle%');
    }

    final rows = await db.query(
      table,
      where: wheres.isEmpty ? null : wheres.join(' AND '),
      whereArgs: wheres.isEmpty ? null : args,
      orderBy: 'updated_at DESC',
      limit: limit,
      offset: offset,
    );
    return rows.map(ServiceRequest.fromMap).toList();
  }

  Future<ServiceRequest?> getById(String serviceRequestId) async {
    final rows = await db.query(
      table,
      where: 'service_request_id = ?',
      whereArgs: [serviceRequestId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ServiceRequest.fromMap(rows.first);
  }

  Future<int> setStatus(String serviceRequestId, ServiceStatus status) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return db.update(
      table,
      {'status': status.index, 'updated_at': now},
      where: 'service_request_id = ?',
      whereArgs: [serviceRequestId],
    );
  }

  Future<int> setWorker(String serviceRequestId, String? workerId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return db.update(
      table,
      {'worker_id': workerId, 'updated_at': now},
      where: 'service_request_id = ?',
      whereArgs: [serviceRequestId],
    );
  }

  Future<int> delete(String serviceRequestId) =>
    db.delete(table, where: 'service_request_id = ?', whereArgs: [serviceRequestId]);

}