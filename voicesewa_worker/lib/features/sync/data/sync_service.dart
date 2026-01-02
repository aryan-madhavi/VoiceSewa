import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voicesewa_worker/core/database/dao/worker_pending_sync_dao.dart';
import 'package:voicesewa_worker/features/sync/domain/worker_pending_sync_model.dart';

class WorkerSyncService {
  final WorkerPendingSyncDao pendingDao;
  final FirebaseFirestore firestore;
  
  Timer? _periodicTimer;
  bool _isSyncing = false;

  WorkerSyncService({
    required this.pendingDao,
    required this.firestore,
  });

  /// Initialize periodic sync
  void initialize() {
    print('🔄 Starting periodic sync (every 30 seconds)...');
    
    // Run initial sync after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      syncPending();
    });

    // Start periodic sync every 30 seconds
    _periodicTimer = Timer.periodic(
      const Duration(minutes: 15),
      (_) => syncPending(),
    );
  }

  /// Check internet connectivity
  Future<bool> _hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    } catch (e) {
      print('⚠️ Network check error: $e');
      return false;
    }
  }

  /// Manually trigger sync
  /// Returns a map with sync results: {'success': bool, 'synced': int, 'failed': int, 'skipped': bool}
  Future<Map<String, dynamic>> syncPending() async {
    if (_isSyncing) {
      print('⏳ Sync already in progress, skipping...');
      return {'success': false, 'synced': 0, 'failed': 0, 'skipped': true};
    }

    _isSyncing = true;
    print('🔄 Starting sync...');

    try {
      // 1. Check internet connection first
      final hasInternet = await _hasInternetConnection();
      if (!hasInternet) {
        print('❌ No internet connection, skipping sync');
        return {'success': false, 'synced': 0, 'failed': 0, 'noInternet': true};
      }

      // 2. Reset any items stuck in "syncing" state
      await _resetStuckItems();

      // 3. Get pending items
      final pendingItems = await pendingDao.getPending(limit: 50);

      if (pendingItems.isEmpty) {
        print('✅ No pending items to sync');
        return {'success': true, 'synced': 0, 'failed': 0};
      }

      print('📤 Syncing ${pendingItems.length} items...');

      // 4. Track sync results
      int successCount = 0;
      int failedCount = 0;

      for (final item in pendingItems) {
        final success = await _syncItem(item);
        if (success) {
          successCount++;
        } else {
          failedCount++;
        }
      }

      // 5. Report results
      if (failedCount > 0) {
        print('⚠️ Sync completed with errors: $successCount succeeded, $failedCount failed');
        return {'success': false, 'synced': successCount, 'failed': failedCount};
      } else {
        print('✅ Sync completed successfully: $successCount items synced');
        return {'success': true, 'synced': successCount, 'failed': 0};
      }
    } catch (e) {
      print('❌ Sync failed: $e');
      return {'success': false, 'synced': 0, 'failed': 0, 'error': e.toString()};
    } finally {
      _isSyncing = false;
    }
  }

  /// Reset items that are stuck in "syncing" status
  /// (This can happen if the app crashes during sync)
  Future<void> _resetStuckItems() async {
    try {
      final stuckItems = await pendingDao.getSyncing();
      if (stuckItems.isNotEmpty) {
        print('🔧 Resetting ${stuckItems.length} stuck items...');
        for (final item in stuckItems) {
          await pendingDao.updateStatus(
            id: item.id,
            status: WorkerSyncStatus.pending,
          );
        }
      }
    } catch (e) {
      print('⚠️ Error resetting stuck items: $e');
    }
  }

  /// Sync a single item
  /// Returns true if successful, false if failed
  Future<bool> _syncItem(WorkerPendingSync item) async {
    try {
      print('📤 Syncing ${item.entityType}:${item.entityId} (${item.action})');

      // Mark as syncing
      await pendingDao.updateStatus(
        id: item.id,
        status: WorkerSyncStatus.syncing,
      );

      // Perform the actual sync based on entity type and action
      await _performFirestoreSync(item);

      // Mark as completed and delete from queue
      await pendingDao.delete(item.id);
      print('✅ Successfully synced ${item.entityId}');
      return true;
      
    } on SocketException catch (e) {
      print('❌ Network error syncing ${item.entityId}: $e');
      await _handleSyncFailure(item, 'Network error: No internet connection');
      return false;
      
    } on TimeoutException catch (e) {
      print('❌ Timeout syncing ${item.entityId}: $e');
      await _handleSyncFailure(item, 'Timeout: Request took too long');
      return false;
      
    } on FirebaseException catch (e) {
      print('❌ Firebase error syncing ${item.entityId}: ${e.code} - ${e.message}');
      await _handleSyncFailure(item, 'Firebase error: ${e.message}');
      return false;
      
    } catch (e) {
      print('❌ Failed to sync ${item.entityId}: $e');
      await _handleSyncFailure(item, e.toString());
      return false;
    }
  }

  /// Handle sync failure for an item
  Future<void> _handleSyncFailure(WorkerPendingSync item, String error) async {
    try {
      // Mark as failed with error details
      await pendingDao.markFailed(item, error: error);
      
      // If retry count is less than max (e.g., 3), reset to pending for next attempt
      if (item.retryCount < 2) {
        print('🔄 Will retry ${item.entityId} (attempt ${item.retryCount + 1}/3)');
        await pendingDao.updateStatus(
          id: item.id,
          status: WorkerSyncStatus.pending,
        );
      } else {
        print('🚫 Max retries reached for ${item.entityId}, marking as permanently failed');
      }
    } catch (e) {
      print('⚠️ Error handling sync failure: $e');
    }
  }

  /// Perform the actual Firestore sync operation
  Future<void> _performFirestoreSync(WorkerPendingSync item) async {
    final collection = firestore.collection(item.entityType);
    
    switch (item.action) {
      case 'INSERT':
      case 'UPDATE':
        // Parse payload and upsert to Firestore
        final data = _parsePayload(item.payload);
        await collection.doc(item.entityId).set(
          data,
          SetOptions(merge: true),
        ).timeout(const Duration(seconds: 10));
        break;

      case 'DELETE':
        // Delete from Firestore
        await collection.doc(item.entityId).delete()
            .timeout(const Duration(seconds: 10));
        break;

      default:
        throw Exception('Unknown action: ${item.action}');
    }
  }

  /// Parse JSON payload string to Map
  Map<String, dynamic> _parsePayload(String payload) {
    try {
      return json.decode(payload) as Map<String, dynamic>;
    } catch (e) {
      print('⚠️ Error parsing payload: $e');
      print('Payload: $payload');
      rethrow;
    }
  }

  /// Get current sync status
  Future<Map<String, int>> getSyncStatus() async {
    try {
      final pendingCount = await pendingDao.getPendingCount();
      final failedCount = await pendingDao.getFailedCount();

      return {
        'pending': pendingCount,
        'failed': failedCount,
      };
    } catch (e) {
      print('❌ Error getting sync status: $e');
      return {'pending': 0, 'failed': 0};
    }
  }

  /// Retry all failed items
  Future<void> retryFailed() async {
    try {
      final failedItems = await pendingDao.getFailed();
      
      print('🔄 Retrying ${failedItems.length} failed items...');
      
      for (final item in failedItems) {
        // Reset status to pending
        await pendingDao.updateStatus(
          id: item.id,
          status: WorkerSyncStatus.pending,
          retryCount: 0,
        );
      }
      
      // Trigger sync
      await syncPending();
    } catch (e) {
      print('❌ Failed to retry items: $e');
    }
  }

  /// Clear all completed items
  Future<void> clearCompleted() async {
    try {
      // This is handled automatically when items are deleted after successful sync
      print('✅ Completed items are automatically cleared');
    } catch (e) {
      print('❌ Error clearing completed items: $e');
    }
  }

  /// Dispose and cleanup
  void dispose() {
    print('🛑 Stopping periodic sync...');
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }
}