import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_worker/core/providers/database_provider.dart';
import 'package:voicesewa_worker/core/database/dao/worker_pending_sync_dao.dart';
import 'package:voicesewa_worker/features/sync/data/sync_service.dart';

/// Stream provider for Firebase Auth state changes
final authStateChangesProvider = StreamProvider.autoDispose<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Provides the DAO for pending sync
final pendingSyncDaoProvider = FutureProvider.autoDispose<WorkerPendingSyncDao>((ref) async {
  print('🔧 Creating WorkerPendingSyncDao...');
  
  final db = await ref.watch(sqfliteDatabaseProvider.future);
  
  // Verify database is actually open
  try {
    await db.rawQuery('SELECT 1');
  } catch (e) {
    print('⚠️ Database verification failed: $e');
    throw StateError('Database not ready: $e');
  }
  
  final dao = WorkerPendingSyncDao(db);
  
  print('✅ WorkerPendingSyncDao ready');
  return dao;
});

/// Provides the SyncService once the DAO is ready
final syncServiceProvider = FutureProvider.autoDispose<WorkerSyncService?>((ref) async {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.value;

  // Graceful exit: If no user, just return null
  if (user == null || user.email == null) {
    print('⏳ SyncService waiting for user login...');
    return null;
  }
  
  final userEmail = user.email!;
  print('🔄 Initializing SyncService for user: $userEmail');
  
  try {
    // Wait for DAO to be ready
    final dao = await ref.watch(pendingSyncDaoProvider.future);

    // Create sync service instance
    final service = WorkerSyncService(
      pendingDao: dao,
      firestore: FirebaseFirestore.instance,
    );

    // Initialize the service
    service.initialize();
    print('✅ SyncService initialized and running for $userEmail');

    // Dispose service when provider is destroyed
    ref.onDispose(() {
      print('🧹 Disposing SyncService for user: $userEmail');
      service.dispose();
    });

    return service;
  } catch (e) {
    print('❌ Failed to initialize SyncService for $userEmail: $e');
    rethrow;
  }
});

/// Provides the current sync status
final syncStatusProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  try {
    final syncService = await ref.watch(syncServiceProvider.future);
    return await syncService?.getSyncStatus() ?? {'pending': 0, 'failed': 0};
  } catch (e) {
    print('❌ Failed to getSyncStatus: $e');
    return {'pending': 0, 'failed': 0};
  }
});