import 'package:sqflite/sqflite.dart';
import 'package:voicesewa_client/core/database/tables/client_profile_table.dart';
import 'package:voicesewa_client/features/auth/domain/client_model.dart';
import 'package:voicesewa_client/core/database/daos/client_pending_sync_dao.dart';
import 'package:voicesewa_client/features/sync/domain/client_pending_sync_model.dart';
import 'dart:convert';

class ClientProfileDao {
  final Database db;
  final ClientPendingSyncDao syncDao; // ✅ Add this

  ClientProfileDao(this.db, this.syncDao); // ✅ Update constructor

  /// Helper method to queue sync (similar to ServiceRequestDao)
  Future<void> _queueSync(String clientId, String action, ClientProfile? profile) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    Map<String, dynamic> payload = {};
    if (action == 'DELETE') {
      payload = {'clientId': clientId};
    } else if (profile != null) {
      payload = profile.toMap();
    }

    final syncRecord = ClientPendingSync(
      id: '$clientId-$now',
      entityType: 'client_profile', // ✅ New entity type
      entityId: clientId,
      action: action,
      payload: jsonEncode(payload),
      queuedAt: now,
      retryCount: 0,
      syncStatus: ClientSyncStatus.pending,
      lastError: null,
    );

    await syncDao.enqueue(syncRecord);
  }

  /// Insert or update a client profile
  Future<int> upsert(ClientProfile profile) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final map = profile.toMap();
    map['updated_at'] = now;

    // Check if profile exists
    final existing = await get(profile.clientId);
    final action = existing == null ? 'INSERT' : 'UPDATE';

    final result = await db.insert(
      ClientProfileTable.table,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // ✅ Queue sync after local insert
    await _queueSync(profile.clientId, action, profile);
    
    return result;
  }

  /// Get a client profile by clientId
  Future<ClientProfile?> get(String clientId) async {
    final rows = await db.query(
      ClientProfileTable.table,
      where: 'client_id = ?',
      whereArgs: [clientId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ClientProfile.fromMap(rows.first);
  }

  /// Optional: get all clients
  Future<List<ClientProfile>> getAll() async {
    final rows = await db.query(ClientProfileTable.table);
    return rows.map(ClientProfile.fromMap).toList();
  }

  /// Optional: delete a client
  Future<int> delete(String clientId) async {
    // Get profile before deleting (for sync payload)
    final profile = await get(clientId);
    
    final result = await db.delete(
      ClientProfileTable.table,
      where: 'client_id = ?',
      whereArgs: [clientId],
    );

    // ✅ Queue delete sync
    if (result > 0) {
      await _queueSync(clientId, 'DELETE', null);
    }

    return result;
  }
}