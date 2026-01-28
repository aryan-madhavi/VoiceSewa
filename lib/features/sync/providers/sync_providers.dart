// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:voicesewa_client/core/providers/database_provider.dart';
// import 'package:voicesewa_client/core/database/daos/client_pending_sync_dao.dart';
// import 'package:voicesewa_client/features/auth/providers/auth_provider.dart';
// import 'package:voicesewa_client/features/sync/data/sync_service.dart';

// /// Provides the DAO for pending sync
// final pendingSyncDaoProvider = FutureProvider.autoDispose<ClientPendingSyncDao>((ref) async {
//   print('🔧 Creating ClientPendingSyncDao...');
  
//   final db = await ref.watch(sqfliteDatabaseProvider.future);
  
//   // Verify database is actually open
//   try {
//     await db.rawQuery('SELECT 1');
//   } catch (e) {
//     print('⚠️ Database verification failed: $e');
//     throw StateError('Database not ready: $e');
//   }
  
//   final dao = ClientPendingSyncDao(db);
  
//   print('✅ ClientPendingSyncDao ready');
//   return dao;
// });

// /// Provides the SyncService once the DAO is ready
// final syncServiceProvider = FutureProvider.autoDispose<SyncService?>((ref) async {

//   final authState = ref.watch(authStateChangesProvider);
//   final user = authState.value;

//   // 2. GRACEFUL EXIT: If no user, just return null. Do NOT throw error.
//   if (user == null || user.email == null) {
//     print('⏳ SyncService waiting for user login...');
//     return null;
//   }
  
//   final userEmail = user.email!;
//   print('🔄 Initializing SyncService for user: $userEmail');
  
//   try {
//     // Wait for DAO to be ready
//     final dao = await ref.watch(pendingSyncDaoProvider.future);

//     // Create sync service instance
//     final service = SyncService(
//       pendingDao: dao,
//       firestore: FirebaseFirestore.instance,
//     );

//     // Initialize the service
//     service.initialize();
//     print('✅ SyncService initialized and running for $userEmail');

//     // Dispose service when provider is destroyed
//     ref.onDispose(() {
//       print('🧹 Disposing SyncService for user: $userEmail');
//       service.dispose();
//     });

//     return service;
//   } catch(e) {
//     print('❌ Failed to initialize SyncService for $userEmail: $e');
//     rethrow;
//   }
// });

// /// Provides the current sync status
// final syncStatusProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
//   try {
//     final syncService = await ref.watch(syncServiceProvider.future);
//     return await syncService?.getSyncStatus() ?? {'pending': 0, 'failed': 0};
//   } catch(e) {
//     print('❌ Failed to getSyncStatus: $e');
//     rethrow;
//   }
// });