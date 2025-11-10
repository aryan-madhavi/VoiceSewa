import 'package:sqflite/sqflite.dart';

Future<void> installServiceRequestSyncTriggers(Database db) async {
  // INSERT TRIGGER
  await db.execute('''
  CREATE TRIGGER IF NOT EXISTS trg_sr_after_insert
  AFTER INSERT ON service_requests
  BEGIN
    INSERT INTO client_pending_sync(
      id, entity_type, entity_id, action, payload, queued_at, retry_count, sync_status
    )
    VALUES (
      NEW.service_request_id  || '-' || CAST(strftime('%s','now') AS INTEGER)*1000,
      'service_requests',
      NEW.service_request_id ,
      'INSERT',
      json_object(
        'serviceRequestId', NEW.service_request_id ,
        'clientId', NEW.client_id,
        'workerId', NEW.worker_id,
        'category', NEW.category,
        'title', NEW.title,
        'description', NEW.description,
        'location', NEW.location,
        'scheduledAt', NEW.scheduled_at,
        'createdAt', NEW.created_at,
        'updatedAt', NEW.updated_at,
        'status', NEW.status
      ),
      CAST(strftime('%s','now') AS INTEGER)*1000,
      0,
      0
    );
  END;
  ''');

  // UPDATE TRIGGER
  await db.execute('''
  CREATE TRIGGER IF NOT EXISTS trg_sr_after_update
  AFTER UPDATE ON service_requests
  BEGIN
    INSERT INTO client_pending_sync(
      id, entity_type, entity_id, action, payload, queued_at, retry_count, sync_status
    )
    VALUES (
      NEW.service_request_id  || '-' || CAST(strftime('%s','now') AS INTEGER)*1000,
      'service_requests',
      NEW.service_request_id ,
      'UPDATE',
      json_object(
        'serviceRequestId', NEW.service_request_id ,
        'clientId', NEW.client_id,
        'workerId', NEW.worker_id,
        'category', NEW.category,
        'title', NEW.title,
        'description', NEW.description,
        'location', NEW.location,
        'scheduledAt', NEW.scheduled_at,
        'createdAt', NEW.created_at,
        'updatedAt', NEW.updated_at,
        'status', NEW.status
      ),
      CAST(strftime('%s','now') AS INTEGER)*1000,
      0,
      0
    );
  END;
  ''');

  // DELETE TRIGGER
  await db.execute('''
  CREATE TRIGGER IF NOT EXISTS trg_sr_after_delete
  AFTER DELETE ON service_requests
  BEGIN
    INSERT INTO client_pending_sync(
      id, entity_type, entity_id, action, payload, queued_at, retry_count, sync_status
    )
    VALUES (
      OLD.service_request_id  || '-' || CAST(strftime('%s','now') AS INTEGER)*1000,
      'service_requests',
      OLD.service_request_id ,
      'DELETE',
      json_object(
        'serviceRequestId', OLD.service_request_id 
      ),
      CAST(strftime('%s','now') AS INTEGER)*1000,
      0,
      0
    );
  END;
  ''');
}
