import 'package:sqflite/sqflite.dart';

/// Install all sync triggers for worker database tables
Future<void> installWorkerSyncTriggers(Database db) async {
  await installWorkerProfileSyncTriggers(db);
  await installJobOfferSyncTriggers(db);
  await installBookingSyncTriggers(db);
}

/// Worker Profile Sync Triggers
Future<void> installWorkerProfileSyncTriggers(Database db) async {
  // INSERT TRIGGER
  await db.execute('''
    CREATE TRIGGER IF NOT EXISTS trg_worker_profile_after_insert
    AFTER INSERT ON worker_profile
    BEGIN
      INSERT INTO worker_pending_sync(
        id, entity_type, entity_id, action, payload, queued_at, retry_count, sync_status
      )
      VALUES (
        NEW.worker_id || '-' || CAST(strftime('%s','now') AS INTEGER)*1000,
        'worker_profile',
        NEW.worker_id,
        'INSERT',
        '{"workerId":"' || NEW.worker_id || 
        '","name":"' || NEW.name || 
        '","phone":"' || NEW.phone || 
        '","language":"' || NEW.language || 
        '","skillCategory":"' || NEW.skill_category || 
        '","bio":"' || COALESCE(NEW.bio, '') || 
        '","updatedAt":' || NEW.updated_at || '}',
        CAST(strftime('%s','now') AS INTEGER)*1000,
        0,
        0
      );
    END;
  ''');

  // UPDATE TRIGGER
  await db.execute('''
    CREATE TRIGGER IF NOT EXISTS trg_worker_profile_after_update
    AFTER UPDATE ON worker_profile
    BEGIN
      INSERT INTO worker_pending_sync(
        id, entity_type, entity_id, action, payload, queued_at, retry_count, sync_status
      )
      VALUES (
        NEW.worker_id || '-' || CAST(strftime('%s','now') AS INTEGER)*1000,
        'worker_profile',
        NEW.worker_id,
        'UPDATE',
        '{"workerId":"' || NEW.worker_id || 
        '","name":"' || NEW.name || 
        '","phone":"' || NEW.phone || 
        '","language":"' || NEW.language || 
        '","skillCategory":"' || NEW.skill_category || 
        '","bio":"' || COALESCE(NEW.bio, '') || 
        '","updatedAt":' || NEW.updated_at || '}',
        CAST(strftime('%s','now') AS INTEGER)*1000,
        0,
        0
      );
    END;
  ''');

  // DELETE TRIGGER
  await db.execute('''
    CREATE TRIGGER IF NOT EXISTS trg_worker_profile_after_delete
    AFTER DELETE ON worker_profile
    BEGIN
      INSERT INTO worker_pending_sync(
        id, entity_type, entity_id, action, payload, queued_at, retry_count, sync_status
      )
      VALUES (
        OLD.worker_id || '-' || CAST(strftime('%s','now') AS INTEGER)*1000,
        'worker_profile',
        OLD.worker_id,
        'DELETE',
        '{"workerId":"' || OLD.worker_id || '"}',
        CAST(strftime('%s','now') AS INTEGER)*1000,
        0,
        0
      );
    END;
  ''');
}

/// Job Offer Sync Triggers
Future<void> installJobOfferSyncTriggers(Database db) async {
  // INSERT TRIGGER
  await db.execute('''
    CREATE TRIGGER IF NOT EXISTS trg_job_offer_after_insert
    AFTER INSERT ON job_offers
    BEGIN
      INSERT INTO worker_pending_sync(
        id, entity_type, entity_id, action, payload, queued_at, retry_count, sync_status
      )
      VALUES (
        NEW.id || '-' || CAST(strftime('%s','now') AS INTEGER)*1000,
        'job_offers',
        NEW.id,
        'INSERT',
        '{"id":"' || NEW.id || 
        '","clientId":"' || NEW.client_id || 
        '","title":"' || NEW.title || 
        '","description":"' || COALESCE(NEW.description, '') || 
        '","location":"' || COALESCE(NEW.location, '') || 
        '","createdAt":' || NEW.created_at || 
        ',"status":' || NEW.status || '}',
        CAST(strftime('%s','now') AS INTEGER)*1000,
        0,
        0
      );
    END;
  ''');

  // UPDATE TRIGGER
  await db.execute('''
    CREATE TRIGGER IF NOT EXISTS trg_job_offer_after_update
    AFTER UPDATE ON job_offers
    BEGIN
      INSERT INTO worker_pending_sync(
        id, entity_type, entity_id, action, payload, queued_at, retry_count, sync_status
      )
      VALUES (
        NEW.id || '-' || CAST(strftime('%s','now') AS INTEGER)*1000,
        'job_offers',
        NEW.id,
        'UPDATE',
        '{"id":"' || NEW.id || 
        '","clientId":"' || NEW.client_id || 
        '","title":"' || NEW.title || 
        '","description":"' || COALESCE(NEW.description, '') || 
        '","location":"' || COALESCE(NEW.location, '') || 
        '","createdAt":' || NEW.created_at || 
        ',"status":' || NEW.status || '}',
        CAST(strftime('%s','now') AS INTEGER)*1000,
        0,
        0
      );
    END;
  ''');

  // DELETE TRIGGER
  await db.execute('''
    CREATE TRIGGER IF NOT EXISTS trg_job_offer_after_delete
    AFTER DELETE ON job_offers
    BEGIN
      INSERT INTO worker_pending_sync(
        id, entity_type, entity_id, action, payload, queued_at, retry_count, sync_status
      )
      VALUES (
        OLD.id || '-' || CAST(strftime('%s','now') AS INTEGER)*1000,
        'job_offers',
        OLD.id,
        'DELETE',
        '{"id":"' || OLD.id || '"}',
        CAST(strftime('%s','now') AS INTEGER)*1000,
        0,
        0
      );
    END;
  ''');
}

/// Booking Sync Triggers
Future<void> installBookingSyncTriggers(Database db) async {
  // INSERT TRIGGER
  await db.execute('''
    CREATE TRIGGER IF NOT EXISTS trg_booking_after_insert
    AFTER INSERT ON bookings
    BEGIN
      INSERT INTO worker_pending_sync(
        id, entity_type, entity_id, action, payload, queued_at, retry_count, sync_status
      )
      VALUES (
        NEW.booking_id || '-' || CAST(strftime('%s','now') AS INTEGER)*1000,
        'bookings',
        NEW.booking_id,
        'INSERT',
        '{"bookingId":"' || NEW.booking_id || 
        '","jobOfferId":"' || NEW.job_offer_id || 
        '","workerId":"' || NEW.worker_id || 
        '","clientId":"' || NEW.client_id || 
        '","scheduledAt":' || NEW.scheduled_at || 
        ',"status":' || NEW.status || 
        ',"updatedAt":' || NEW.updated_at || '}',
        CAST(strftime('%s','now') AS INTEGER)*1000,
        0,
        0
      );
    END;
  ''');

  // UPDATE TRIGGER
  await db.execute('''
    CREATE TRIGGER IF NOT EXISTS trg_booking_after_update
    AFTER UPDATE ON bookings
    BEGIN
      INSERT INTO worker_pending_sync(
        id, entity_type, entity_id, action, payload, queued_at, retry_count, sync_status
      )
      VALUES (
        NEW.booking_id || '-' || CAST(strftime('%s','now') AS INTEGER)*1000,
        'bookings',
        NEW.booking_id,
        'UPDATE',
        '{"bookingId":"' || NEW.booking_id || 
        '","jobOfferId":"' || NEW.job_offer_id || 
        '","workerId":"' || NEW.worker_id || 
        '","clientId":"' || NEW.client_id || 
        '","scheduledAt":' || NEW.scheduled_at || 
        ',"status":' || NEW.status || 
        ',"updatedAt":' || NEW.updated_at || '}',
        CAST(strftime('%s','now') AS INTEGER)*1000,
        0,
        0
      );
    END;
  ''');

  // DELETE TRIGGER
  await db.execute('''
    CREATE TRIGGER IF NOT EXISTS trg_booking_after_delete
    AFTER DELETE ON bookings
    BEGIN
      INSERT INTO worker_pending_sync(
        id, entity_type, entity_id, action, payload, queued_at, retry_count, sync_status
      )
      VALUES (
        OLD.booking_id || '-' || CAST(strftime('%s','now') AS INTEGER)*1000,
        'bookings',
        OLD.booking_id,
        'DELETE',
        '{"bookingId":"' || OLD.booking_id || '"}',
        CAST(strftime('%s','now') AS INTEGER)*1000,
        0,
        0
      );
    END;
  ''');
}