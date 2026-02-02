import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:voicesewa_client/features/jobs/firebase/job_firebase_service.dart';
import 'package:voicesewa_client/features/jobs/repository/job_repository.dart';
import 'package:voicesewa_client/shared/data/services_data.dart';
import 'package:voicesewa_client/shared/models/address_model.dart';
import 'package:voicesewa_client/shared/models/job_model.dart';

// ==================== SERVICE & REPOSITORY PROVIDERS ====================

/// Provider for Job Firebase service
final jobFirebaseServiceProvider = Provider<JobFirebaseService>((ref) {
  return JobFirebaseService();
});

/// Provider for Job repository
final jobRepositoryProvider = Provider<JobRepository>((ref) {
  final service = ref.watch(jobFirebaseServiceProvider);
  return JobRepository(service);
});

// ==================== DATA PROVIDERS ====================

/// Provider to get all jobs for current user
final currentUserJobsProvider = StreamProvider.autoDispose<List<Job>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    print('⚠️ No user logged in');
    return Stream.value([]);
  }

  print('👤 Watching jobs for user UID: ${user.uid}');
  final repository = ref.watch(jobRepositoryProvider);
  return repository.watchClientJobs(user.uid);
});

/// Provider to get jobs by status for current user
final jobsByStatusProvider = StreamProvider.autoDispose
    .family<List<Job>, JobStatus>((ref, status) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return Stream.value([]);
      }

      final repository = ref.watch(jobRepositoryProvider);
      return repository.watchJobsByStatus(user.uid, status);
    });

/// Provider to get a specific job with real-time updates
final jobProvider = StreamProvider.autoDispose.family<Job?, String>((
  ref,
  jobId,
) {
  final repository = ref.watch(jobRepositoryProvider);
  return repository.watchJob(jobId);
});

/// Provider to get recent jobs (for home screen)
final recentJobsProvider = StreamProvider.autoDispose<List<Job>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return Stream.value([]);
  }

  final repository = ref.watch(jobRepositoryProvider);
  return repository.watchRecentJobs(user.uid, limit: 5);
});

// ==================== ACTIONS PROVIDER ====================

/// Provider for job actions (create, cancel, reschedule, etc.)
final jobActionsProvider = Provider<JobActions>((ref) {
  final repository = ref.watch(jobRepositoryProvider);
  return JobActions(repository, ref);
});

/// Job actions class
class JobActions {
  final JobRepository _repository;
  final Ref _ref;

  JobActions(this._repository, this._ref);

  /// Create a new job
  /// ✅ scheduledAt is when the client wants the job done (REQUIRED)
  Future<String> createJob({
    required Services serviceType,
    required String description,
    required Address address,
    required DateTime scheduledAt, // ✅ REQUIRED: When client wants job done
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    print('🆕 Creating job for user UID: ${user.uid}');
    print('📅 Scheduled for: ${scheduledAt.toIso8601String()}');

    final jobId = await _repository.createJob(
      serviceType: serviceType,
      description: description,
      address: address,
      clientUid: user.uid,
      scheduledAt: scheduledAt, // ✅ Client sets when they want it done
    );

    // Invalidate caches to refresh UI
    _ref.invalidate(currentUserJobsProvider);
    _ref.invalidate(recentJobsProvider);

    return jobId;
  }

  /// Cancel a job
  Future<void> cancelJob(String jobId, String reason) async {
    await _repository.cancelJob(jobId, reason);

    // Invalidate caches
    _ref.invalidate(currentUserJobsProvider);
    _ref.invalidate(jobProvider(jobId));
  }

  /// Reschedule a job
  Future<void> rescheduleJob(String jobId, DateTime newScheduledAt) async {
    await _repository.rescheduleJob(jobId, newScheduledAt);

    // Invalidate caches
    _ref.invalidate(currentUserJobsProvider);
    _ref.invalidate(jobProvider(jobId));
  }

  /// Mark job as in progress
  Future<void> startJob(String jobId) async {
    await _repository.startJob(jobId);

    // Invalidate caches
    _ref.invalidate(currentUserJobsProvider);
    _ref.invalidate(jobProvider(jobId));
  }

  /// Mark job as completed
  Future<void> completeJob(String jobId) async {
    await _repository.completeJob(jobId);

    // Invalidate caches
    _ref.invalidate(currentUserJobsProvider);
    _ref.invalidate(jobProvider(jobId));
  }
}
