import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../domain/client_pending_sync_model.dart';
import '../../../core/database/daos/client_pending_sync_dao.dart';

class SyncService {
  SyncService({
    required ClientPendingSyncDao pendingDao,
    required FirebaseFirestore firestore,
  })  : _pendingDao = pendingDao,
        _firestore = firestore;

  final ClientPendingSyncDao _pendingDao;
  final FirebaseFirestore _firestore;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _periodicTimer;

  bool _isSyncing = false;
  bool _initialized = false;

  /* ================= INTERNET ================= */

  Future<bool> _hasInternet() async {
    final result = await Connectivity().checkConnectivity();
    if (!result.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet)) {
      return false;
    }

    try {
      await _firestore
          .collection('_ping')
          .limit(1)
          .get(const GetOptions(source: Source.server));
      return true;
    } catch (e) {
      print('❌ Internet check failed: $e');
      return false;
    }
  }

  /* ================= SYNC ================= */

  Future<void> syncPending() async {
    if (_isSyncing) {
      print('⏭️ Sync already in progress, skipping...');
      return;
    }

    _isSyncing = true;

    try {
      if (!await _hasInternet()) {
        print('📵 No internet connection, skipping sync');
        return;
      }

      print('✅ Internet available, triggering sync');

      print('🔄 Starting sync...');

      final items = await _pendingDao.getPending(limit: 50);

      print('📋 Found ${items.length} pending items to sync');

      for (final item in items) {
        await _syncOne(item);
      }

      final result = await getSyncStatus();
      final failed = result['failed'] ?? 0;
      final pending = result['pending'] ?? 0;
      print('✅ Sync completed - Success: ${items.length - failed}, Failed: $failed, Pending: $pending');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncOne(ClientPendingSync item) async {
    print('🔄 Syncing: ${item.action} ${item.entityType}/${item.entityId}');
    try {
      if (item.entityType == 'service_requests') {
        final data = jsonDecode(item.payload);
        final converted = _convertTimestamps(data);

        print('📤 Sending data to Firestore: $converted');
        final ref =
            _firestore.collection('service_requests').doc(item.entityId);

        switch (item.action) {
          case 'INSERT':
          case 'UPDATE':
            await ref.set(converted, SetOptions(merge: true));
            print('✅ Successfully synced: ${item.entityId}');
            break;
          case 'DELETE':
            await ref.delete();
            print('🗑️ Successfully deleted: ${item.entityId}');
            break;
        }
      }

      await _pendingDao.delete(item.id);
    } catch (e, st) {
      print('❌ Sync failed for ${item.entityId}: $e');
      print('Stack trace: $st');
      await _pendingDao.markFailed(item, error: e.toString());
    }
  }

  /// Force a sync immediately
  Future<void> forceSyncNow() async {
    print('👆 Force sync requested');
    await syncPending();
  }

  /// Return the current sync status
  /// Map contains 'pending' and 'failed' counts
  Future<Map<String, int>> getSyncStatus() async {
    final pending = await _pendingDao.getPendingCount();
    final failed = await _pendingDao.getFailedCount();
    print('📊 Sync status - Pending: $pending, Failed: $failed');
    return {
      'pending': pending,
      'failed': failed,
    };
  }

  //TODO: Retrying failed syncs logic implementation
/* Future<void> syncFailed() async {
    print('🔄 Retrying failed syncs');
  } */

  /* ================= TIMESTAMPS ================= */

  Map<String, dynamic> _convertTimestamps(Map<String, dynamic> data) {
    final result = Map<String, dynamic>.from(data);

    print('🔧 Converting timestamps in data: $data');

    Timestamp? convert(String k, dynamic v) {
      if (v == null || v <= 0) {
        print('⏭️ Skipping $k: null or less than equal to 0');
        return null;
      }
      if (v is int && v > 0) {
        print('✅ Converting $k: $v ms -> Timestamp');
        return Timestamp.fromMillisecondsSinceEpoch(v);
      }
      if (v is Timestamp) {
        print('✅ $k already a Timestamp');
        return v;
      }
      print('⚠️ Unknown type for $k: ${v.runtimeType}');
      return null;
    }

    for (final key in ['createdAt', 'updatedAt', 'scheduledAt']) {
      final ts = convert(key, result[key]);
      if (ts != null) {
        result[key] = ts;
      } else {
        result.remove(key);
      }
    }

    print('✅ Converted data: $result');
    return result;
  }

  /* ================= LIFECYCLE ================= */

  void initialize() {
    if (_initialized) {
      print('⚠️ SyncService already initialized, skipping');
      return;
    }

    print('🚀 Initializing SyncService on app start');
    _initialized = true;

    startConnectivityListener();
    startPeriodicSync();

    print('🔄 Running immediate sync on initialization');
    Future.delayed(const Duration(seconds: 2), () { 
      print('🚀 Running initial sync'); 
      syncPending(); 
    });
  }

  void startConnectivityListener() {
    print('👂 Starting connectivity listener');
    _connectivitySub?.cancel();
    _connectivitySub =
        Connectivity().onConnectivityChanged.listen(
            (_) => syncPending(), 
            onError: (e) => print('❌ Connectivity listener error: $e')
        );
  }

  void startPeriodicSync({Duration interval = const Duration(minutes: 10)}) {
    print('⏰ Starting periodic sync (interval: ${interval.inMinutes} minutes)');
    _periodicTimer =
        Timer.periodic(interval, (_) { 
          print('⏰ Periodic sync triggered');
          syncPending();
        });
  }

  void dispose() {
    print('🧹 Disposing SyncService');
    _connectivitySub?.cancel();
    _periodicTimer?.cancel();
    _initialized = false;
  }
}
