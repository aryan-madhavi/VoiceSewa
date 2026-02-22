import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_worker/features/profile/data/repositories/worker_profile_repository.dart';
import 'package:voicesewa_worker/shared/models/worker_model.dart';

// ── Repository provider ────────────────────────────────────────────────────

final workerProfileRepositoryProvider = Provider<WorkerProfileRepository>((
  ref,
) {
  return WorkerProfileRepository();
});

// ── Check if worker has a profile in Firestore ────────────────────────────

/// Returns true if a `workers/{uid}` document exists in Firestore.
/// Uses Firestore offline cache automatically when device is offline.
final userHasProfileProvider = FutureProvider.autoDispose.family<bool, String>((
  ref,
  uid,
) async {
  if (uid.isEmpty) return false;
  final repo = ref.watch(workerProfileRepositoryProvider);
  return repo.hasProfile(uid);
});

// ── Fetch the full worker profile ─────────────────────────────────────────

final workerProfileProvider = FutureProvider.autoDispose
    .family<WorkerModel?, String>((ref, uid) async {
      if (uid.isEmpty) return null;
      final repo = ref.watch(workerProfileRepositoryProvider);
      return repo.getProfile(uid);
    });

// ── Stream the worker profile for real-time UI updates ────────────────────

final workerProfileStreamProvider = StreamProvider.autoDispose
    .family<WorkerModel?, String>((ref, uid) {
      if (uid.isEmpty) return const Stream.empty();
      final repo = ref.watch(workerProfileRepositoryProvider);
      return repo.watchProfile(uid);
    });

// ── Save / update worker profile ──────────────────────────────────────────

final saveWorkerProfileProvider = Provider<Future<bool> Function(WorkerModel)>((
  ref,
) {
  return (WorkerModel worker) async {
    final repo = ref.read(workerProfileRepositoryProvider);
    final success = await repo.saveProfile(worker);

    if (success) {
      // Invalidate cached providers so UI reflects new data
      ref.invalidate(userHasProfileProvider);
      ref.invalidate(workerProfileProvider);
    }

    return success;
  };
});
