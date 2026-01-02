
enum BookingStatus { pending, confirmed, inProgress, completed, cancelled }

class Booking {
  final String bookingId;
  final String jobOfferId;
  final String workerId;
  final String clientId;
  final int scheduledAt;
  final BookingStatus status;
  final int updatedAt;

  Booking({
    required this.bookingId,
    required this.jobOfferId,
    required this.workerId,
    required this.clientId,
    required this.scheduledAt,
    required this.status,
    required this.updatedAt,
  });

  Map<String, Object?> toMap() => {
    'booking_id': bookingId,
    'job_offer_id': jobOfferId,
    'worker_id': workerId,
    'client_id': clientId,
    'scheduled_at': scheduledAt,
    'status': status.index,
    'updated_at': updatedAt,
  };

  static Booking fromMap(Map<String, Object?> m) => Booking(
    bookingId: m['booking_id'] as String,
    jobOfferId: m['job_offer_id'] as String,
    workerId: m['worker_id'] as String,
    clientId: m['client_id'] as String,
    scheduledAt: m['scheduled_at'] as int,
    status: BookingStatus.values[m['status'] as int],
    updatedAt: m['updated_at'] as int,
  );
}

class BookingTable {
  static const table = 'bookings';
  static const createSql =
      '''
  CREATE TABLE IF NOT EXISTS $table(
    booking_id TEXT PRIMARY KEY,
    job_offer_id TEXT NOT NULL,
    worker_id TEXT NOT NULL,
    client_id TEXT NOT NULL,
    scheduled_at INTEGER NOT NULL,
    status INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  );
  ''';
}
