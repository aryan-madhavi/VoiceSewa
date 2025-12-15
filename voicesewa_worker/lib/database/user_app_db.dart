import 'dart:async';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'tables/worker_profile_table.dart';
import 'tables/job_offer_table.dart';
import 'tables/booking_table.dart';
import 'tables/pending_sync_table.dart';

class AppDatabase {

 static const _dbname = 'voicesewa_worker.db';
  static const _dbversion = 1;  

  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();  

  Database? _db;
  Future<Database> get database async {
    if (_db != null) return _db!;

    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, _dbname);
    _db = await openDatabase(
      path,
      version: _dbversion,
      onCreate: (db, v) async {
        await db.execute(WorkerProfileTable.createSql);
        await db.execute(JobOfferTable.createSql);
        await db.execute(BookingTable.createSql);
        await db.execute(PendingSyncTable.createSql);


        await db.execute('CREATE INDEX IF NOT EXISTS idx_booking_status ON bookings(status);');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_job_offer_status ON job_offers(status);');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_sync_status ON pending_sync(sync_status);');

      },
    );

    return _db!;
  }

}