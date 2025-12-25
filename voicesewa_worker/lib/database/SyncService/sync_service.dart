import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:voicesewa_client/database/tables/client_pending_sync_table.dart';

class SyncService {
  final Database local_db;
  final FirebaseFirestore firestore_db;
  
  // Store the subscription to prevent garbage collection
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _periodicSyncTimer;
  bool _isSyncing = false;
  bool _isInitialized = false;

  SyncService(this.local_db, this.firestore_db);

  Future<bool> _hasInternetConnection() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.wifi) ||
        connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.ethernet)) {
      try {
        await firestore_db
            .collection('_ping')
            .limit(1)
            .get(const GetOptions(source: Source.server));
        return true;
      } catch (e) {
        print('Internet check failed: $e');
        return false;
      }
    }
    return false;
  }

  Future<void> syncPending() async {
    // Prevent multiple simultaneous syncs
    if (_isSyncing) {
      print('Sync already in progress, skipping...');
      return;
    }

    _isSyncing = true;
    try {
      if (!await _hasInternetConnection()) {
        print('No internet connection, skipping sync');
        return;
      }

      print('Starting sync...');
      
      final rows = await local_db.query(
        ClientPendingSyncTable.table,
        where: 'sync_status = ?',
        whereArgs: [ClientSyncStatus.pending.index],
        orderBy: 'queued_at ASC, retry_count ASC',
        limit: 50,
      );

      print('Found ${rows.length} pending items to sync');

      for (final r in rows) {
        final id = r['id'] as String;
        final entityType = r['entity_type'] as String;
        final entityId = r['entity_id'] as String;
        final action = r['action'] as String;
        final payload = r['payload'] as String;

        try {
          print('Syncing: $action $entityType/$entityId');

          if (entityType == 'service_requests') {
            final data = jsonDecode(payload) as Map<String, dynamic>;
            
            // Convert integer timestamps to Firestore Timestamps
            final firestoreData = _convertTimestampsForFirestore(data);
            
            final docRef = firestore_db.collection('service_requests').doc(entityId);

            if (action == 'INSERT' || action == 'UPDATE') {
              await docRef.set(firestoreData, SetOptions(merge: true));
              print('Successfully synced: $entityId');
            } else if (action == 'DELETE') {
              await docRef.delete();
              print('Successfully deleted: $entityId');
            }
          }

          // Remove from sync queue after successful sync
          await local_db.delete(
            ClientPendingSyncTable.table,
            where: 'id = ?',
            whereArgs: [id],
          );

        } catch (e) {
          print('Sync failed for $entityId: $e');
          
          final retryCount = (r['retry_count'] as int?) ?? 0;
          
          // Mark as failed after 5 retries
          if (retryCount >= 5) {
            await local_db.update(
              ClientPendingSyncTable.table,
              {
                'sync_status': ClientSyncStatus.failed.index,
                'last_error': e.toString(),
              },
              where: 'id = ?',
              whereArgs: [id],
            );
          } else {
            await local_db.update(
              ClientPendingSyncTable.table,
              {
                'retry_count': retryCount + 1,
                'last_error': e.toString(),
              },
              where: 'id = ?',
              whereArgs: [id],
            );
          }
        }
      }
      
      print('Sync completed');
    } catch (e) {
      print('Sync error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // Convert integer milliseconds to Firestore Timestamps
  Map<String, dynamic> _convertTimestampsForFirestore(Map<String, dynamic> data) {
    final converted = Map<String, dynamic>.from(data);
    
    // Convert timestamp fields
    if (converted['createdAt'] != null && converted['createdAt'] is int) {
      converted['createdAt'] = Timestamp.fromMillisecondsSinceEpoch(converted['createdAt']);
    }
    if (converted['updatedAt'] != null && converted['updatedAt'] is int) {
      converted['updatedAt'] = Timestamp.fromMillisecondsSinceEpoch(converted['updatedAt']);
    }
    if (converted['scheduledAt'] != null && converted['scheduledAt'] is int) {
      converted['scheduledAt'] = Timestamp.fromMillisecondsSinceEpoch(converted['scheduledAt']);
    }
    
    return converted;
  }

  // Start listening to connectivity changes
  void startConnectivityListener() {
    print('Starting connectivity listener');
    
    // Cancel existing subscription if any
    _connectivitySubscription?.cancel();
    
    // Listen to connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        print('Connectivity changed: $results');
        if (results.contains(ConnectivityResult.wifi) ||
            results.contains(ConnectivityResult.mobile) ||
            results.contains(ConnectivityResult.ethernet)) {
          print('Internet available, triggering sync');
          // Add a small delay to ensure connection is stable
          Future.delayed(const Duration(seconds: 2), () {
            syncPending();
          });
        }
      },
      onError: (error) {
        print('Connectivity listener error: $error');
      },
    );

    // Run initial sync after a short delay to allow app to fully initialize
    print('Scheduling initial sync on app start');
    Future.delayed(const Duration(seconds: 3), () async {
      print('Running initial sync');
      await syncPending();
    });
  }

  // Start periodic sync (every 5 minutes)
  void startPeriodicSync({Duration interval = const Duration(minutes: 10)}) {
    print('Starting periodic sync (interval: ${interval.inMinutes} minutes)');
    
    _periodicSyncTimer?.cancel();
    
    _periodicSyncTimer = Timer.periodic(interval, (_) {
      print('Periodic sync triggered');
      syncPending();
    });
  }

  // Initialize both listeners - call this when app starts
  void initialize() {
    if (_isInitialized) {
      print('⚠️ SyncService already initialized, skipping');
      return;
    }
    
    print('🚀 Initializing SyncService on app start');
    _isInitialized = true;
    
    startConnectivityListener();
    startPeriodicSync();
    
    // Also run immediate sync on initialization (with shorter delay)
    print('Running immediate sync on initialization');
    Future.delayed(const Duration(seconds: 1), () async {
      await syncPending();
    });
  }

  // Clean up resources
  void dispose() {
    print('Disposing SyncService');
    _connectivitySubscription?.cancel();
    _periodicSyncTimer?.cancel();
    _isInitialized = false;
  }

  // Manual sync trigger (for pull-to-refresh, etc.)
  Future<void> forceSyncNow() async {
    print('Force sync requested');
    await syncPending();
  }

  // Get sync status
  Future<Map<String, int>> getSyncStatus() async {
    final pending = await local_db.query(
      ClientPendingSyncTable.table,
      where: 'sync_status = ?',
      whereArgs: [ClientSyncStatus.pending.index],
    );
    
    final failed = await local_db.query(
      ClientPendingSyncTable.table,
      where: 'sync_status = ?',
      whereArgs: [ClientSyncStatus.failed.index],
    );

    return {
      'pending': pending.length,
      'failed': failed.length,
    };
  }

  // Retry all failed syncs
  Future<void> retryFailedSyncs() async {
    print('Retrying all failed syncs');
    
    await local_db.update(
      ClientPendingSyncTable.table,
      {
        'sync_status': ClientSyncStatus.pending.index,
        'retry_count': 0,
        'last_error': null,
      },
      where: 'sync_status = ?',
      whereArgs: [ClientSyncStatus.failed.index],
    );
    
    await syncPending();
  }
}