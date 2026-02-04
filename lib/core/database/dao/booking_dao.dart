import 'package:sqflite/sqflite.dart';
import 'package:voicesewa_worker/core/database/tables/booking_table.dart';

class BookingDao {
  final Database db;

  BookingDao(this.db);

  /// Insert or update a booking
  /// Sync is handled by SQL triggers automatically
  Future<int> upsert(Booking booking) {
    return db.insert(
      BookingTable.table,
      booking.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get a booking by ID
  Future<Booking?> getById(String bookingId) async {
    final rows = await db.query(
      BookingTable.table,
      where: 'booking_id = ?',
      whereArgs: [bookingId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Booking.fromMap(rows.first);
  }

  /// Get all bookings with optional filters
  Future<List<Booking>> getAll({
    BookingStatus? status,
    String? workerId,
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
    if (workerId != null) {
      wheres.add('worker_id = ?');
      args.add(workerId);
    }
    if (clientId != null) {
      wheres.add('client_id = ?');
      args.add(clientId);
    }

    final rows = await db.query(
      BookingTable.table,
      where: wheres.isEmpty ? null : wheres.join(' AND '),
      whereArgs: wheres.isEmpty ? null : args,
      orderBy: 'updated_at DESC',
      limit: limit,
      offset: offset,
    );

    return rows.map(Booking.fromMap).toList();
  }

  /// Update booking status
  Future<int> setStatus(String bookingId, BookingStatus status) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return db.update(
      BookingTable.table,
      {'status': status.index, 'updated_at': now},
      where: 'booking_id = ?',
      whereArgs: [bookingId],
    );
  }

  /// Delete a booking
  Future<int> delete(String bookingId) {
    return db.delete(
      BookingTable.table,
      where: 'booking_id = ?',
      whereArgs: [bookingId],
    );
  }

  /// Get upcoming bookings (scheduled in the future)
  Future<List<Booking>> getUpcoming({String? workerId}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final wheres = <String>['scheduled_at > ?'];
    final args = <Object?>[now];

    if (workerId != null) {
      wheres.add('worker_id = ?');
      args.add(workerId);
    }

    final rows = await db.query(
      BookingTable.table,
      where: wheres.join(' AND '),
      whereArgs: args,
      orderBy: 'scheduled_at ASC',
    );

    return rows.map(Booking.fromMap).toList();
  }

  /// Get past bookings
  Future<List<Booking>> getPast({String? workerId}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final wheres = <String>['scheduled_at <= ?'];
    final args = <Object?>[now];

    if (workerId != null) {
      wheres.add('worker_id = ?');
      args.add(workerId);
    }

    final rows = await db.query(
      BookingTable.table,
      where: wheres.join(' AND '),
      whereArgs: args,
      orderBy: 'scheduled_at DESC',
    );

    return rows.map(Booking.fromMap).toList();
  }

  /// Get count by status
  Future<int> countByStatus(BookingStatus status) async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${BookingTable.table} WHERE status = ?',
      [status.index],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
