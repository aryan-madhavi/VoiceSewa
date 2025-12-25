import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:voicesewa_client/features/auth/data/tables/client_pending_sync_table.dart';

class SyncService {
  final Database local_db;
  final FirebaseFirestore firestore_db;
  
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
        print('❌ Internet check failed: $e');
        return false;
      }
    }
    return false;
  }

  Future<void> syncPending() async {
    if (_isSyncing) {
      print('⏭️  Sync already in progress, skipping...');
      return;
    }

    _isSyncing = true;
    int successCount = 0;
    int failCount = 0;
    
    try {
      if (!await _hasInternetConnection()) {
        print('📵 No internet connection, skipping sync');
        return;
      }

      print('🔄 Starting sync...');
      
      final rows = await local_db.query(
        ClientPendingSyncTable.table,
        where: 'sync_status = ?',
        whereArgs: [ClientSyncStatus.pending.index],
        orderBy: 'queued_at ASC, retry_count ASC',
        limit: 50,
      );

      print('📋 Found ${rows.length} pending items to sync');

      for (final r in rows) {
        final id = r['id'] as String;
        final entityType = r['entity_type'] as String;
        final entityId = r['entity_id'] as String;
        final action = r['action'] as String;
        final payload = r['payload'] as String;

        try {
          print('🔄 Syncing: $action $entityType/$entityId');

          if (entityType == 'service_requests') {
            final data = jsonDecode(payload) as Map<String, dynamic>;
            
            // FIXED: Convert timestamps BEFORE sending to Firestore
            final firestoreData = _convertTimestampsForFirestore(data);
            
            print('📤 Sending data to Firestore: $firestoreData');
            
            final docRef = firestore_db.collection('service_requests').doc(entityId);

            if (action == 'INSERT' || action == 'UPDATE') {
              // Use merge:true to avoid overwriting other fields
              await docRef.set(firestoreData, SetOptions(merge: true));
              print('✅ Successfully synced: $entityId');
              successCount++;
            } else if (action == 'DELETE') {
              await docRef.delete();
              print('🗑️  Successfully deleted: $entityId');
              successCount++;
            }
          }

          // Remove from sync queue after successful sync
          await local_db.delete(
            ClientPendingSyncTable.table,
            where: 'id = ?',
            whereArgs: [id],
          );

        } catch (e, stackTrace) {
          print('❌ Sync failed for $entityId: $e');
          print('Stack trace: $stackTrace');
          failCount++;
          
          final retryCount = (r['retry_count'] as int?) ?? 0;
          
          // Mark as failed after 5 retries
          if (retryCount >= 5) {
            print('🔴 Max retries reached for $entityId, marking as failed');
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
            print('🔄 Retry ${retryCount + 1}/5 for $entityId');
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
      
      print('✅ Sync completed - Success: $successCount, Failed: $failCount');
    } catch (e, stackTrace) {
      print('❌ Sync error: $e');
      print('Stack trace: $stackTrace');
    } finally {
      _isSyncing = false;
    }
  }

  // FIXED: Better timestamp conversion with proper null handling
  Map<String, dynamic> _convertTimestampsForFirestore(Map<String, dynamic> data) {
    final converted = Map<String, dynamic>.from(data);
    
    print('🔧 Converting timestamps in data: $data');
    
    // Helper function to convert timestamp
    Timestamp? convertField(String fieldName) {
      final value = converted[fieldName];
      if (value == null || value == 0) {
        print('⏭️  Skipping $fieldName: null or 0');
        return null;
      }
      if (value is int) {
        print('✅ Converting $fieldName: $value ms -> Timestamp');
        return Timestamp.fromMillisecondsSinceEpoch(value);
      }
      if (value is Timestamp) {
        print('✅ $fieldName already a Timestamp');
        return value;
      }
      print('⚠️  Unknown type for $fieldName: ${value.runtimeType}');
      return null;
    }
    
    // Convert all timestamp fields
    final createdAt = convertField('createdAt');
    if (createdAt != null) converted['createdAt'] = createdAt;
    
    final updatedAt = convertField('updatedAt');
    if (updatedAt != null) converted['updatedAt'] = updatedAt;
    
    final scheduledAt = convertField('scheduledAt');
    if (scheduledAt != null) converted['scheduledAt'] = scheduledAt;
    
    // Remove fields with value 0 to avoid issues
    converted.removeWhere((key, value) => value == 0 && (key.contains('At') || key.contains('at')));
    
    print('✅ Converted data: $converted');
    return converted;
  }

  void startConnectivityListener() {
    print('👂 Starting connectivity listener');
    
    _connectivitySubscription?.cancel();
    
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        print('📶 Connectivity changed: $results');
        if (results.contains(ConnectivityResult.wifi) ||
            results.contains(ConnectivityResult.mobile) ||
            results.contains(ConnectivityResult.ethernet)) {
          print('✅ Internet available, triggering sync');
          Future.delayed(const Duration(seconds: 2), () {
            syncPending();
          });
        }
      },
      onError: (error) {
        print('❌ Connectivity listener error: $error');
      },
    );

    print('⏰ Scheduling initial sync on app start');
    Future.delayed(const Duration(seconds: 3), () async {
      print('🚀 Running initial sync');
      await syncPending();
    });
  }

  void startPeriodicSync({Duration interval = const Duration(minutes: 10)}) {
    print('⏰ Starting periodic sync (interval: ${interval.inMinutes} minutes)');
    
    _periodicSyncTimer?.cancel();
    
    _periodicSyncTimer = Timer.periodic(interval, (_) {
      print('⏰ Periodic sync triggered');
      syncPending();
    });
  }

  void initialize() {
    if (_isInitialized) {
      print('⚠️  SyncService already initialized, skipping');
      return;
    }
    
    print('🚀 Initializing SyncService on app start');
    _isInitialized = true;
    
    startConnectivityListener();
    startPeriodicSync();
    
    print('🔄 Running immediate sync on initialization');
    Future.delayed(const Duration(seconds: 1), () async {
      await syncPending();
    });
  }

  void dispose() {
    print('🧹 Disposing SyncService');
    _connectivitySubscription?.cancel();
    _periodicSyncTimer?.cancel();
    _isInitialized = false;
  }

  Future<void> forceSyncNow() async {
    print('👆 Force sync requested');
    await syncPending();
  }

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

    print('📊 Sync status - Pending: ${pending.length}, Failed: ${failed.length}');
    
    return {
      'pending': pending.length,
      'failed': failed.length,
    };
  }

  Future<void> retryFailedSyncs() async {
    print('🔄 Retrying all failed syncs');
    
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

  // ADDED: Debug method to see what's in the sync queue
  Future<List<Map<String, dynamic>>> getPendingItems() async {
    final rows = await local_db.query(
      ClientPendingSyncTable.table,
      where: 'sync_status IN (?, ?)',
      whereArgs: [ClientSyncStatus.pending.index, ClientSyncStatus.failed.index],
      orderBy: 'queued_at ASC',
    );
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }
}