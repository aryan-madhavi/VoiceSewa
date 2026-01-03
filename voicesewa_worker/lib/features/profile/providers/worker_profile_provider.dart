import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_worker/core/database/dao/worker_profile_dao.dart';
import 'package:voicesewa_worker/core/database/tables/worker_profile_table.dart';
import 'package:voicesewa_worker/core/database/app_database.dart';
import 'package:voicesewa_worker/core/providers/database_provider.dart';

/// Provider to check if user has completed their profile
/// Returns true if profile exists, false if it needs to be created
final profileCompletionProvider = FutureProvider.autoDispose.family<bool, String>((
  ref,
  userId,
) async {
  print('🔍 Checking profile completion for user: $userId');

  if (userId.isEmpty) {
    print('❌ Empty userId provided');
    return false;
  }

  try {
    // Ensure WorkerDatabase is initialized for this user
    WorkerDatabase.instanceForUser(userId);
    await Future.delayed(const Duration(milliseconds: 50));

    // Get the database instance using the family provider
    final db = await ref.watch(sqfliteDatabaseProvider(userId).future);

    // Create DAO
    final dao = WorkerProfileDao(db);

    // Check if profile exists for this user
    final profile = await dao.get(userId);

    final isComplete = profile != null;
    print(
      isComplete
          ? '✅ Profile exists for user: $userId'
          : '⚠️ No profile found for user: $userId (first-time user)',
    );

    return isComplete;
  } catch (e) {
    print('❌ Error checking profile completion: $e');
    // On error, assume profile doesn't exist (safe default for first-time users)
    return false;
  }
});

/// Provider to get the current worker profile
final workerProfileProvider = FutureProvider.autoDispose
    .family<WorkerProfile?, String>((ref, userId) async {
      print('📋 Fetching worker profile for: $userId');

      if (userId.isEmpty) {
        print('❌ Empty userId provided');
        return null;
      }

      try {
        // Ensure WorkerDatabase is initialized
        WorkerDatabase.instanceForUser(userId);
        await Future.delayed(const Duration(milliseconds: 50));

        final db = await ref.watch(sqfliteDatabaseProvider(userId).future);
        final dao = WorkerProfileDao(db);

        final profile = await dao.get(userId);

        if (profile != null) {
          print('✅ Profile loaded: ${profile.name}');
        } else {
          print('⚠️ No profile found');
        }

        return profile;
      } catch (e) {
        print('❌ Error fetching profile: $e');
        return null;
      }
    });

/// Provider to save/update worker profile
final saveWorkerProfileProvider =
    Provider<Future<bool> Function(WorkerProfile)>((ref) {
      return (WorkerProfile profile) async {
        print('💾 Saving worker profile for: ${profile.workerId}');

        if (profile.workerId.isEmpty) {
          print('❌ Empty workerId in profile');
          return false;
        }

        try {
          // Ensure WorkerDatabase is initialized
          WorkerDatabase.instanceForUser(profile.workerId);
          await Future.delayed(const Duration(milliseconds: 50));

          final db = await ref.watch(
            sqfliteDatabaseProvider(profile.workerId).future,
          );
          final dao = WorkerProfileDao(db);

          // Upsert the profile (insert or update)
          await dao.upsert(profile);

          print('✅ Profile saved successfully');

          // Invalidate the profile providers to refresh
          ref.invalidate(profileCompletionProvider);
          ref.invalidate(workerProfileProvider);

          return true;
        } catch (e) {
          print('❌ Error saving profile: $e');
          return false;
        }
      };
    });
