// import 'package:sqflite/sqflite.dart';

// Future<void> installServiceRequestSyncTriggers(Database db) async {
//   // INSERT TRIGGER
//   await db.execute('''
//   CREATE TRIGGER IF NOT EXISTS trg_sr_after_insert
//   AFTER INSERT ON service_requests
//   BEGIN
//     INSERT INTO client_pending_sync(
//       id, entity_type, entity_id, action, payload, queued_at, retry_count, sync_status
//     )
//     VALUES (
//       NEW.service_request_id || '-' || CAST(strftime('%s','now') AS INTEGER)*1000,
//       'service_requests',
//       NEW.service_request_id,
//       'INSERT',
//       json_object(
//         'serviceRequestId', COALESCE(NEW.service_request_id, ''),
//         'clientId', COALESCE(NEW.client_id, ''),
//         'workerId', COALESCE(NEW.worker_id, ''),
//         'category', COALESCE(NEW.category, ''),
//         'title', COALESCE(NEW.title, ''),
//         'description', COALESCE(NEW.description, ''),
//         'location', COALESCE(NEW.location, ''),
//         'scheduledAt', COALESCE(NEW.scheduled_at, 0),
//         'createdAt', COALESCE(NEW.created_at, 0),
//         'updatedAt', COALESCE(NEW.updated_at, 0),
//         'status', COALESCE(NEW.status, 0)
//       ),
//       CAST(strftime('%s','now') AS INTEGER)*1000,
//       0,
//       0
//     );
//   END;
//   ''');

//   // UPDATE TRIGGER
//   await db.execute('''
//   CREATE TRIGGER IF NOT EXISTS trg_sr_after_update
//   AFTER UPDATE ON service_requests
//   BEGIN
//     INSERT INTO client_pending_sync(
//       id, entity_type, entity_id, action, payload, queued_at, retry_count, sync_status
//     )
//     VALUES (
//       NEW.service_request_id || '-' || CAST(strftime('%s','now') AS INTEGER)*1000,
//       'service_requests',
//       NEW.service_request_id,
//       'UPDATE',
//       json_object(
//         'serviceRequestId', COALESCE(NEW.service_request_id, ''),
//         'clientId', COALESCE(NEW.client_id, ''),
//         'workerId', COALESCE(NEW.worker_id, ''),
//         'category', COALESCE(NEW.category, ''),
//         'title', COALESCE(NEW.title, ''),
//         'description', COALESCE(NEW.description, ''),
//         'location', COALESCE(NEW.location, ''),
//         'scheduledAt', COALESCE(NEW.scheduled_at, 0),
//         'createdAt', COALESCE(NEW.created_at, 0),
//         'updatedAt', COALESCE(NEW.updated_at, 0),
//         'status', COALESCE(NEW.status, 0)
//       ),
//       CAST(strftime('%s','now') AS INTEGER)*1000,
//       0,
//       0
//     );
//   END;
//   ''');

//   // DELETE TRIGGER
//   await db.execute('''
//   CREATE TRIGGER IF NOT EXISTS trg_sr_after_delete
//   AFTER DELETE ON service_requests
//   BEGIN
//     INSERT INTO client_pending_sync(
//       id, entity_type, entity_id, action, payload, queued_at, retry_count, sync_status
//     )
//     VALUES (
//       OLD.service_request_id || '-' || CAST(strftime('%s','now') AS INTEGER)*1000,
//       'service_requests',
//       OLD.service_request_id,
//       'DELETE',
//       json_object(
//         'serviceRequestId', COALESCE(OLD.service_request_id, '')
//       ),
//       CAST(strftime('%s','now') AS INTEGER)*1000,
//       0,
//       0
//     );
//   END;
//   ''');
// }