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
    } catch (_) {
      return false;
    }
  }

  /* ================= SYNC ================= */

  Future<void> syncPending() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      if (!await _hasInternet()) return;

      final items = await _pendingDao.getPending(limit: 50);

      for (final item in items) {
        await _syncOne(item);
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncOne(ClientPendingSync item) async {
    try {
      if (item.entityType == 'service_requests') {
        final data = jsonDecode(item.payload);
        final converted = _convertTimestamps(data);

        final ref =
            _firestore.collection('service_requests').doc(item.entityId);

        switch (item.action) {
          case 'INSERT':
          case 'UPDATE':
            await ref.set(converted, SetOptions(merge: true));
            break;
          case 'DELETE':
            await ref.delete();
            break;
        }
      }

      await _pendingDao.delete(item.id);
    } catch (e) {
      await _pendingDao.markFailed(item, error: e.toString());
    }
  }

  /// Force a sync immediately
  Future<void> forceSyncNow() async {
    await syncPending();
  }

  /// Return the current sync status
  /// Map contains 'pending' and 'failed' counts
  Future<Map<String, int>> getSyncStatus() async {
    final pending = await _pendingDao.getPendingCount();
    final failed = await _pendingDao.getFailedCount();
    return {
      'pending': pending,
      'failed': failed,
    };
  }

  /* ================= TIMESTAMPS ================= */

  Map<String, dynamic> _convertTimestamps(Map<String, dynamic> data) {
    final result = Map<String, dynamic>.from(data);

    Timestamp? convert(dynamic v) {
      if (v is int && v > 0) {
        return Timestamp.fromMillisecondsSinceEpoch(v);
      }
      if (v is Timestamp) return v;
      return null;
    }

    for (final key in ['createdAt', 'updatedAt', 'scheduledAt']) {
      final ts = convert(result[key]);
      if (ts != null) {
        result[key] = ts;
      } else {
        result.remove(key);
      }
    }

    return result;
  }

  /* ================= LIFECYCLE ================= */

  void initialize() {
    if (_initialized) return;
    _initialized = true;

    _connectivitySub =
        Connectivity().onConnectivityChanged.listen((_) => syncPending());

    _periodicTimer =
        Timer.periodic(const Duration(minutes: 10), (_) => syncPending());

    Future.delayed(const Duration(seconds: 2), syncPending);
  }

  void dispose() {
    _connectivitySub?.cancel();
    _periodicTimer?.cancel();
    _initialized = false;
  }
}
