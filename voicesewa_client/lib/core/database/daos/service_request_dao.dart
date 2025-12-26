import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:voicesewa_client/core/database/tables/service_request_table.dart';
import 'package:voicesewa_client/features/sync/domain/client_pending_sync_model.dart';
import 'package:voicesewa_client/features/service_requests/domain/service_request_model.dart';
import 'package:voicesewa_client/core/database/daos/client_pending_sync_dao.dart';

class ServiceRequestDao {
  final Database db;
  final ClientPendingSyncDao syncDao;

  ServiceRequestDao(this.db, this.syncDao);

  Future<void> _queueSync(String entityId, String action, ServiceRequest? s) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    Map<String, dynamic> payload = {};
    if (action == 'DELETE') {
      payload = {'serviceRequestId': entityId};
    } else if (s != null) {
      payload = s.toMap();
    }

    final syncRecord = ClientPendingSync(
      id: '$entityId-$now',
      entityType: 'service_requests',
      entityId: entityId,
      action: action,
      payload: jsonEncode(payload),
      queuedAt: now,
      retryCount: 0,
      syncStatus: ClientSyncStatus.pending,
      lastError: null,
    );

    await syncDao.enqueue(syncRecord);
  }

  Future<int> upsert(ServiceRequest s) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final map = s.toMap();
    map['created_at'] ??= now;
    map['updated_at'] ??= now;

    final existing = await getById(s.serviceRequestId);
    final action = existing == null ? 'INSERT' : 'UPDATE';

    final result = await db.insert(
      ServiceRequestTable.table,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await _queueSync(s.serviceRequestId, action, s);
    return result;
  }

  Future<ServiceRequest?> getById(String id) async {
    final rows = await db.query(
      ServiceRequestTable.table,
      where: 'service_request_id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ServiceRequest.fromMap(rows.first);
  }

  Future<List<ServiceRequest>> all({ServiceStatus? status, String? clientId, String? workerId}) async {
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

    final rows = await db.query(
      ServiceRequestTable.table,
      where: wheres.isEmpty ? null : wheres.join(' AND '),
      whereArgs: wheres.isEmpty ? null : args,
      orderBy: 'updated_at DESC',
    );

    return rows.map(ServiceRequest.fromMap).toList();
  }

  Future<int> setStatus(String serviceRequestId, ServiceStatus status) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final result = await db.update(
      ServiceRequestTable.table,
      {'status': status.index, 'updated_at': now},
      where: 'service_request_id = ?',
      whereArgs: [serviceRequestId],
    );

    final updated = await getById(serviceRequestId);
    if (updated != null) {
      await _queueSync(serviceRequestId, 'UPDATE', updated);
    }

    return result;
  }

  Future<int> setWorker(String serviceRequestId, String? workerId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final result = await db.update(
      ServiceRequestTable.table,
      {'worker_id': workerId, 'updated_at': now},
      where: 'service_request_id = ?',
      whereArgs: [serviceRequestId],
    );

    final updated = await getById(serviceRequestId);
    if (updated != null) {
      await _queueSync(serviceRequestId, 'UPDATE', updated);
    }

    return result;
  }

  Future<int> delete(String serviceRequestId) async {
    final result = await db.delete(
      ServiceRequestTable.table,
      where: 'service_request_id = ?',
      whereArgs: [serviceRequestId],
    );

    await _queueSync(serviceRequestId, 'DELETE', null);

    return result;
  }
}

