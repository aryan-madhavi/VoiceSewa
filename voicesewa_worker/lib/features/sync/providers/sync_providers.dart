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

/// Provides the DAO for pending sync - user-specific
final pendingSyncDaoProvider = FutureProvider.family
    .autoDispose<WorkerPendingSyncDao, String>((ref, userId) async {
      print('🔧 Creating WorkerPendingSyncDao for $userId...');

      final db = await ref.watch(sqfliteDatabaseProvider.future);

      try {
        await db.rawQuery('SELECT 1');
      } catch (e) {
        print('⚠️ Database verification failed: $e');
        throw StateError('Database not ready: $e');
      }

      final dao = WorkerPendingSyncDao(db);

      print('✅ WorkerPendingSyncDao ready for $userId');
      return dao;
    });

/// Provides the SyncService - user-specific
final syncServiceProvider = FutureProvider.family
    .autoDispose<WorkerSyncService?, String>((ref, userId) async {
      print('🔄 Initializing SyncService for user: $userId');

      try {
        // Wait for database
        await ref.watch(sqfliteDatabaseProvider.future);

        if (!ref.mounted) {
          print('⚠️ Provider disposed during database init');
          return null;
        }

        // Get DAO for this user
        final dao = await ref.read(pendingSyncDaoProvider(userId).future);

        if (!ref.mounted) {
          print('⚠️ Provider disposed after reading DAO');
          return null;
        }

        final service = WorkerSyncService(
          pendingDao: dao,
          firestore: FirebaseFirestore.instance,
        );

        service.initialize();
        print('✅ SyncService initialized and running for $userId');

        ref.onDispose(() {
          print('🧹 Disposing SyncService for user: $userId');
          service.dispose();
        });

        return service;
      } catch (e) {
        print('❌ Failed to initialize SyncService for $userId: $e');
        rethrow;
      }
    });

/// Provides the current sync status - user-specific
final syncStatusProvider = FutureProvider.family
    .autoDispose<Map<String, int>, String>((ref, userId) async {
      try {
        final WorkerSyncService? syncService = await ref.watch(
          syncServiceProvider(userId).future,
        );

        if (syncService == null) {
          return {'pending': 0, 'failed': 0};
        }

        return await syncService.getSyncStatus();
      } catch (e) {
        print('❌ Failed to getSyncStatus: $e');
        return {'pending': 0, 'failed': 0};
      }
    });
