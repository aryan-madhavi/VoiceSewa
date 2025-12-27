import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/providers/database_provider.dart';
import '../../../core/database/daos/client_pending_sync_dao.dart';
import '../data/sync_service.dart';

/// Provides the DAO for pending sync
final pendingSyncDaoProvider = FutureProvider.autoDispose<ClientPendingSyncDao>((ref) async {
  print('🔧 Creating ClientPendingSyncDao...');
  
  final db = await ref.watch(sqfliteDatabaseProvider.future);
  final dao = ClientPendingSyncDao(db);
  
  print('✅ ClientPendingSyncDao ready');
  return dao;
});

/// Provides the SyncService once the DAO is ready
final syncServiceProvider = FutureProvider.autoDispose<SyncService>((ref) async {
  // Get current user
  final userEmail = FirebaseAuth.instance.currentUser?.email;
  if (userEmail == null) {
    throw StateError('No user logged in');
  }
  
  print('🔄 Initializing SyncService for user: $userEmail');
  
  // Wait for DAO to be ready
  final dao = await ref.watch(pendingSyncDaoProvider.future);

  // Create sync service instance
  final service = SyncService(
    pendingDao: dao,
    firestore: FirebaseFirestore.instance,
  );
  
  // Initialize the service
  service.initialize();
  
  // Dispose service when provider is destroyed
  ref.onDispose(() {
    print('🧹 Disposing SyncService for user: $userEmail');
    service.dispose();
  });

  return service;
});

/// Provides the current sync status
final syncStatusProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final syncService = await ref.watch(syncServiceProvider.future);
  return await syncService.getSyncStatus();
});