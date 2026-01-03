import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:voicesewa_worker/core/database/app_database.dart';

/// Provider for user-specific database instance
/// Takes userId as parameter to avoid race conditions
final sqfliteDatabaseProvider = FutureProvider.autoDispose
    .family<Database, String>((ref, String userId) async {
      if (userId.isEmpty) {
        throw StateError('User ID is empty. Cannot access database.');
      }

      print('👤 Getting database for: $userId');

      try {
        // Ensure database instance exists for this user
        WorkerDatabase.instanceForUser(userId);

        // Small delay to ensure initialization completes
        await Future.delayed(const Duration(milliseconds: 50));

        // Get the database instance using the specific userId
        final instance = WorkerDatabase.instanceForUser(userId);
        final db = await instance.database;

        print('✅ Database ready for: $userId');
        return db;
      } catch (e) {
        print('❌ Error loading database for $userId: $e');
        rethrow;
      }
    });

/// Legacy provider without family parameter (for backward compatibility)
/// Tries to get userId from WorkerDatabase or Firebase
/// USE THIS ONLY FOR OLD CODE - New code should use sqfliteDatabaseProvider(userId)
final sqfliteDatabaseProviderLegacy = FutureProvider.autoDispose<Database>((
  ref,
) async {
  // 1. Get the user ID with proper fallback logic
  String? targetEmail = WorkerDatabase.currentUserId;

  // If WorkerDatabase doesn't have it yet, check Firebase
  if (targetEmail == null || targetEmail.isEmpty) {
    print('⚠️ WorkerDatabase not initialized, checking Firebase...');
    targetEmail = FirebaseAuth.instance.currentUser?.email;

    // If we found it in Firebase, initialize WorkerDatabase immediately
    if (targetEmail != null && targetEmail.isNotEmpty) {
      print('🔧 Initializing WorkerDatabase for: $targetEmail');
      WorkerDatabase.instanceForUser(targetEmail);
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  // 2. If still null, we cannot proceed
  if (targetEmail == null || targetEmail.isEmpty) {
    throw StateError('No user logged in. Cannot access database.');
  }

  // Use the family provider
  return ref.watch(sqfliteDatabaseProvider(targetEmail).future);
});

/// Provider to check if current user has a database
final userHasDatabaseProvider = FutureProvider.autoDispose<bool>((ref) async {
  final userId =
      WorkerDatabase.currentUserId ?? FirebaseAuth.instance.currentUser?.email;

  if (userId == null || userId.isEmpty) return false;

  return await WorkerDatabase.userDatabaseExists(userId);
});

/// Provider to get current user ID
final currentUserIdProvider = Provider<String?>((ref) {
  return WorkerDatabase.currentUserId ??
      FirebaseAuth.instance.currentUser?.email;
});
