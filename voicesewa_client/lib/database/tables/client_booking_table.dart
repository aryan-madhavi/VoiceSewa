import 'package:sqflite/sqflite.dart';

enum ClientBookingStatus { pending, confirmed, inProgress, completed, cancelled }

class ClientBooking {
  final String bookingId;
  final String serviceRequestId;
  final String workerId;
  final String clientId;
  final int scheduledAt;
  final ClientBookingStatus status;
  final int updatedAt;

  ClientBooking({
    required this.bookingId,
    required this.serviceRequestId,
    required this.workerId,
    required this.clientId,
    required this.scheduledAt,
    required this.status,
    required this.updatedAt,
  });

  Map<String, Object?> toMap() => {
    'booking_id': bookingId,
    'service_request_id': serviceRequestId,
    'worker_id': workerId,
    'client_id': clientId,
    'scheduled_at': scheduledAt,
    'status': status.index,
    'updated_at': updatedAt,
  };

  static ClientBooking fromMap(Map<String, Object?> m) => ClientBooking(
    bookingId: m['booking_id'] as String,
    serviceRequestId: m['service_request_id'] as String,
    workerId: m['worker_id'] as String,
    clientId: m['client_id'] as String,
    scheduledAt: m['scheduled_at'] as int,
    status: ClientBookingStatus.values[m['status'] as int],
    updatedAt: m['updated_at'] as int,
  );
}

class ClientBookingTable {
  static const table = 'client_bookings';
  static const createSql = '''
  CREATE TABLE IF NOT EXISTS $table(
    booking_id TEXT PRIMARY KEY,
    service_request_id TEXT NOT NULL,
    worker_id TEXT NOT NULL,
    client_id TEXT NOT NULL,
    scheduled_at INTEGER NOT NULL,
    status INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  );
  ''';

  final Database db;
  ClientBookingTable(this.db);

  Future<int> upsert(ClientBooking b) =>
      db.insert(table, b.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

  Future<List<ClientBooking>> all({ClientBookingStatus? status}) async {
    final rows = await db.query(
      table,
      where: status == null ? null : 'status=?',
      whereArgs: status == null ? null : [status.index],
      orderBy: 'updated_at DESC',
    );
    return rows.map(ClientBooking.fromMap).toList();
  }

  Future<int> setStatus(String bookingId, ClientBookingStatus s) =>
      db.update(table, {'status': s.index, 'updated_at': DateTime.now().millisecondsSinceEpoch},
          where: 'booking_id=?', whereArgs: [bookingId]);
}
