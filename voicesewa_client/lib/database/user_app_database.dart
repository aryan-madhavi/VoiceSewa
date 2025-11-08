import 'dart:async';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'tables/client_profile_table.dart';
import 'tables/service_request_table.dart';
import 'tables/client_booking_table.dart';
import 'tables/client_pending_sync_table.dart';


class ClientDatabase{
  /// It should be unique for each user
  // userid_voicesewa_client.db  
  static const _dbname = 'voicesewa_client.db';
  static const _dbversion = 1;  

  ClientDatabase._();
  static final ClientDatabase instance = ClientDatabase._();  

  Database? _db;


  Future<Database> get database async {
    if (_db != null) return _db!;

    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, _dbname);
    _db = await openDatabase(
      path,
      version: _dbversion,
      onCreate: (db, v) async {
        await db.execute(ClientProfileTable.createSql);
        await db.execute(ServiceRequestTable.createSql);
        await db.execute(ClientBookingTable.createSql);
        await db.execute(ClientPendingSyncTable.createSql);

        await db.execute('CREATE INDEX IF NOT EXISTS idx_sr_status ON service_requests(status);');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_cb_status ON client_bookings(status);');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_csync_status ON client_pending_sync(sync_status);');
      },
    );

    return _db!;
  }
}


