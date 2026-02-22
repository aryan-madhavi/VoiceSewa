import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_worker/features/jobs/repositories/job_repository.dart';
import 'package:voicesewa_worker/features/profile/providers/worker_profile_provider.dart';
import 'package:voicesewa_worker/shared/models/job_model.dart';
import 'package:voicesewa_worker/shared/models/quotation_model.dart';

// ── Repository ─────────────────────────────────────────────────────────────

final jobRepositoryProvider = Provider<JobRepository>((_) => JobRepository());

// ── Current worker UID ────────────────────────────────────────────────────

final currentWorkerUidProvider = Provider<String>((ref) {
  return FirebaseAuth.instance.currentUser?.uid ?? '';
});

// ── Incoming jobs (skill + proximity filtered) ────────────────────────────

final incomingJobsProvider = FutureProvider.autoDispose<List<JobModel>>((ref) async {
  final uid = ref.watch(currentWorkerUidProvider);
  print('🔍 incomingJobsProvider — uid: "$uid"');
  if (uid.isEmpty) {
    print('⚠️  incomingJobsProvider — no uid, returning []');
    return [];
  }

  final profileRepo = ref.watch(workerProfileRepositoryProvider);
  final worker = await profileRepo.getProfile(uid);
  print('🔍 incomingJobsProvider — worker: ${worker?.name}, '
      'skills: ${worker?.skills}, location: ${worker?.address?.location}');

  if (worker == null) {
    print('⚠️  incomingJobsProvider — worker profile null, returning []');
    return [];
  }
  final location = worker.address?.location;
  if (location == null) {
    print('⚠️  incomingJobsProvider — worker has no location, returning []');
    return [];
  }
  if (worker.skills.isEmpty) {
    print('⚠️  incomingJobsProvider — worker has no skills, returning []');
    return [];
  }

  return ref.watch(jobRepositoryProvider).fetchIncomingJobs(
    workerSkills: worker.skills,
    workerLocation: location,
  );
});

// ── Applied jobs ──────────────────────────────────────────────────────────

final appliedJobsProvider = FutureProvider.autoDispose<List<JobModel>>((ref) async {
  final uid = ref.watch(currentWorkerUidProvider);
  if (uid.isEmpty) return [];
  return ref.watch(jobRepositoryProvider).fetchAppliedJobs(uid);
});

// ── Ongoing jobs (stream) ─────────────────────────────────────────────────
// Watches the worker doc's jobs.confirmed ref array.
// The Firebase Function onQuotationAccepted moves refs here automatically
// when a quotation is accepted — no client-side polling needed.

final ongoingJobsProvider = StreamProvider.autoDispose<List<JobModel>>((ref) {
  final uid = ref.watch(currentWorkerUidProvider);
  if (uid.isEmpty) return const Stream.empty();
  return ref.watch(jobRepositoryProvider).watchOngoingJobs(uid);
});

// ── Completed jobs (stream) ───────────────────────────────────────────────

final completedJobsProvider = StreamProvider.autoDispose<List<JobModel>>((ref) {
  final uid = ref.watch(currentWorkerUidProvider);
  if (uid.isEmpty) return const Stream.empty();
  return ref.watch(jobRepositoryProvider).watchCompletedJobs(uid);
});

// ── Submit quotation ──────────────────────────────────────────────────────

final submitQuotationProvider = Provider<
    Future<bool> Function({
      required String jobId,
      required QuotationModel quotation,
    })>((ref) {
  return ({required String jobId, required QuotationModel quotation}) async {
    final uid = ref.read(currentWorkerUidProvider);
    if (uid.isEmpty) return false;
    final success = await ref.read(jobRepositoryProvider).submitQuotation(
      jobId: jobId,
      quotation: quotation,
      workerUid: uid,
    );
    if (success) {
      ref.invalidate(incomingJobsProvider);
      ref.invalidate(appliedJobsProvider);
    }
    return success;
  };
});

// ── Worker's existing quotation for a job ────────────────────────────────

final myQuotationProvider =
    FutureProvider.autoDispose.family<QuotationModel?, String>((ref, jobId) async {
  final uid = ref.watch(currentWorkerUidProvider);
  if (uid.isEmpty) return null;
  return ref.watch(jobRepositoryProvider).fetchMyQuotation(
    jobId: jobId,
    workerUid: uid,
  );
});

// ── Mark job complete ─────────────────────────────────────────────────────

final markJobCompletedProvider = Provider<Future<bool> Function(String)>((ref) {
  return (String jobId) async {
    final uid = ref.read(currentWorkerUidProvider);
    if (uid.isEmpty) return false;
    return ref.read(jobRepositoryProvider).markJobCompleted(
      jobId: jobId,
      workerUid: uid,
    );
  };
});