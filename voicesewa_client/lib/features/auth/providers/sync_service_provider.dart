import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:voicesewa_client/core/providers/database_provider.dart';
import 'package:voicesewa_client/features/auth/data/SyncService/sync_service.dart';

/// Provider for SyncService - auto-initializes when database is ready
final syncServiceProvider = FutureProvider.autoDispose<SyncService>((ref) async {
  final userEmail = FirebaseAuth.instance.currentUser?.email;
  
  if (userEmail == null) {
    throw StateError('No user logged in');
  }
  
  print('🔄 Initializing SyncService for user: $userEmail');
  
  try {
    // Wait for user-specific database to be ready
    final db = await ref.watch(sqfliteDatabaseProvider.future);
    final firestore = FirebaseFirestore.instance;
    
    // Verify database is actually open
    try {
      await db.rawQuery('SELECT 1');
    } catch (e) {
      print('⚠️ Database verification failed: $e');
      throw StateError('Database not ready: $e');
    }
    
    // Create sync service instance
    final syncService = SyncService(db, firestore);
    
    // Initialize sync (starts listeners and triggers initial sync)
    syncService.initialize();
    print('✅ SyncService initialized and running for $userEmail');
    
    // Clean up when provider is disposed
    ref.onDispose(() {
      print('🧹 Disposing SyncService for user: $userEmail');
      syncService.dispose();
    });
    
    return syncService;
  } catch (e) {
    print('❌ Failed to initialize SyncService for $userEmail: $e');
    rethrow;
  }
});

/// Provider to manually trigger sync from UI
final manualSyncProvider = FutureProvider.autoDispose<void>((ref) async {
  final syncServiceAsync = ref.watch(syncServiceProvider);
  
  await syncServiceAsync.when(
    data: (syncService) async {
      print('🔄 Manual sync triggered');
      await syncService.forceSyncNow();
    },
    loading: () async {
      print('⏳ SyncService not ready yet');
    },
    error: (err, stack) async {
      print('❌ Cannot sync: $err');
    },
  );
});

/// Provider to get sync status
final syncStatusProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final syncServiceAsync = ref.watch(syncServiceProvider);
  
  return await syncServiceAsync.when(
    data: (syncService) async {
      return await syncService.getSyncStatus();
    },
    loading: () async => {'pending': 0, 'failed': 0},
    error: (err, stack) async => {'pending': 0, 'failed': 0},
  );
});

/// Provider to retry failed syncs
final retryFailedSyncsProvider = FutureProvider.autoDispose<void>((ref) async {
  final syncServiceAsync = ref.watch(syncServiceProvider);
  
  await syncServiceAsync.when(
    data: (syncService) async {
      print('🔄 Retrying failed syncs');
      await syncService.retryFailedSyncs();
    },
    loading: () async {
      print('⏳ SyncService not ready yet');
    },
    error: (err, stack) async {
      print('❌ Cannot retry syncs: $err');
    },
  );
});