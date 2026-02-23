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

final userHasProfileProvider = FutureProvider.autoDispose.family<bool, String>((
  ref,
  uid,
) async {
  if (uid.isEmpty) return false;
  final repo = ref.watch(workerProfileRepositoryProvider);
  return repo.hasProfile(uid);
});

// ── Fetch the full worker profile (one-shot) ──────────────────────────────

final workerProfileProvider = FutureProvider.autoDispose
    .family<WorkerModel?, String>((ref, uid) async {
      if (uid.isEmpty) return null;
      final repo = ref.watch(workerProfileRepositoryProvider);
      return repo.getProfile(uid);
    });

// ── Stream the worker profile for real-time UI updates ────────────────────
// NOT autoDispose — must stay alive for the entire session so that
// incomingJobsProvider and other providers that depend on the profile
// stream can read a resolved value instead of null.
//
// autoDispose was the root cause of the "no incoming/ongoing jobs" bug:
//   1. incomingJobsProvider watched this stream on first build
//   2. stream hadn't emitted yet → .value == null → returned [] immediately
//   3. FutureProvider never re-ran because it doesn't react to stream changes
//   4. Switching tabs disposed the stream → cold restart next time → same bug

final workerProfileStreamProvider = StreamProvider.family<WorkerModel?, String>(
  (ref, uid) {
    if (uid.isEmpty) return const Stream.empty();
    final repo = ref.watch(workerProfileRepositoryProvider);
    return repo.watchProfile(uid);
  },
);

// ── Save / update worker profile ──────────────────────────────────────────

final saveWorkerProfileProvider = Provider<Future<bool> Function(WorkerModel)>((
  ref,
) {
  return (WorkerModel worker) async {
    final repo = ref.read(workerProfileRepositoryProvider);
    final success = await repo.saveProfile(worker);

    if (success) {
      ref.invalidate(userHasProfileProvider);
      ref.invalidate(workerProfileProvider);
      // workerProfileStreamProvider does NOT need invalidation —
      // it's a live stream that auto-updates when Firestore changes.
    }

    return success;
  };
});
