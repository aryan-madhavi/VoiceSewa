import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:voicesewa_client/database/SyncService/sync_service.dart';
import 'package:voicesewa_client/database/user_app_database.dart';

// Provider for database instance
final databaseProvider = FutureProvider<Database>((ref) async {
  print('🗄️ Initializing database...');
  final dbHelper = ClientDatabase.instance;
  final db = await dbHelper.database;
  print('✅ Database initialized');
  return db;
});

// Provider for SyncService - Changed to FutureProvider for better initialization control
final syncServiceProvider = FutureProvider<SyncService>((ref) async {
  print('🔄 Initializing SyncService...');
  
  // Wait for database to be ready
  final db = await ref.watch(databaseProvider.future);
  final firestore = FirebaseFirestore.instance;
  
  // Create sync service instance
  final syncService = SyncService(db, firestore);
  
  // Initialize sync immediately (this starts listeners and triggers initial sync)
  syncService.initialize();
  print('✅ SyncService initialized and running');
  
  // Clean up when provider is disposed
  ref.onDispose(() {
    print('🧹 Disposing SyncService');
    syncService.dispose();
  });
  
  return syncService;
});

// Optional: Provider to manually trigger sync from UI
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

// Optional: Provider to get sync status
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