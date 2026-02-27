import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_worker/core/providers/session_provider.dart'; // currentUserProvider
import 'package:voicesewa_worker/features/profile/providers/worker_profile_provider.dart';
import 'package:voicesewa_worker/shared/models/job_model.dart';

/// Fetches the full JobModel for every completed job ref stored on the worker document.
final completedJobsProvider = FutureProvider.autoDispose<List<JobModel>>((
  ref,
) async {
  final uid = ref.watch(currentUserProvider)?.uid ?? '';
  if (uid.isEmpty) return [];

  final profileAsync = ref.watch(workerProfileStreamProvider(uid));
  // .valueOrNull is not available in all Riverpod versions — use .when instead
  final worker = profileAsync.when(
    data: (w) => w,
    loading: () => null,
    error: (_, __) => null,
  );
  if (worker == null) return [];

  final completedRefs = worker.jobs.completed;
  if (completedRefs.isEmpty) return [];

  // Fetch all completed job documents in parallel
  final snapshots = await Future.wait(
    completedRefs.map((docRef) => docRef.get()),
  );

  return snapshots
      .where((doc) => doc.exists)
      .map((doc) => JobModel.fromDoc(doc))
      .toList()
    ..sort((a, b) {
      // Most recent first
      final aDate = a.scheduledAt ?? a.createdAt;
      final bDate = b.scheduledAt ?? b.createdAt;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });
});
