import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/database_provider.dart';
import '../../../core/database/daos/client_pending_sync_dao.dart';
import '../data/sync_service.dart';

/// Provides the DAO for pending sync
final pendingSyncDaoProvider =
    FutureProvider<ClientPendingSyncDao>((ref) async {
  final db = await ref.read(sqfliteDatabaseProvider.future);
  return ClientPendingSyncDao(db);
});

/// Provides the SyncService once the DAO is ready
final syncServiceProvider = FutureProvider<SyncService>((ref) async {
  print('🔄 Initializing SyncService...');
  
  // Wait for DAO to be ready
  final dao = await ref.watch(pendingSyncDaoProvider.future);

  // Create sync service instance
  final service = SyncService(
    pendingDao: dao,
    firestore: FirebaseFirestore.instance,
  );

  // Initialize sync immediately (this starts listeners and triggers initial sync)
  service.initialize();
  print('✅ SyncService initialized and running');

  // Dispose service when provider is destroyed
  ref.onDispose((){
    print('🧹 Disposing SyncService');
    service.dispose;
  });

  return service;
});

/// Provides the current sync status
final syncStatusProvider = FutureProvider<Map<String, int>>((ref) async {
  final syncService = await ref.watch(syncServiceProvider.future);
  return await syncService.getSyncStatus();
});
