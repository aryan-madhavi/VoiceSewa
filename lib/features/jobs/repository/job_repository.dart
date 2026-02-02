import 'package:voicesewa_client/features/jobs/firebase/job_firebase_service.dart';
import 'package:voicesewa_client/shared/data/services_data.dart';
import 'package:voicesewa_client/shared/models/address_model.dart';
import 'package:voicesewa_client/shared/models/job_model.dart';

/// Repository for job operations with business logic and validation
class JobRepository {
  final JobFirebaseService _firebaseService;

  JobRepository(this._firebaseService);

  /// Create a new job with validation
  /// ✅ scheduledAt is REQUIRED - client must specify when they want the job
  Future<String> createJob({
    required Services serviceType,
    required String description,
    required Address address,
    required String clientUid,
    required DateTime scheduledAt, // ✅ REQUIRED: When client wants the job
  }) async {
    // Validate input
    _validateJobCreation(description, address, scheduledAt);

    final job = Job(
      id: '', // Will be set by Firestore
      serviceType: serviceType,
      description: description.trim(),
      address: address,
      clientUid: clientUid,
      createdAt: DateTime.now(),
      status: JobStatus.requested,
      scheduledAt: scheduledAt, // ✅ Set when client wants the job
      // ❌ finalized_quotation is NULL during creation
      // It's ONLY set when client accepts a quotation
      finalizedQuotationId: null,
      workerName: null,
      workerRating: null,
    );

    return await _firebaseService.createJob(job);
  }

  void _validateJobCreation(
    String description,
    Address address,
    DateTime scheduledAt,
  ) {
    if (description.trim().isEmpty) {
      throw ArgumentError('Job description cannot be empty');
    }

    if (description.trim().length < 10) {
      throw ArgumentError('Description must be at least 10 characters');
    }

    if (address.line1.isEmpty || address.city.isEmpty) {
      throw ArgumentError('Address must include line1 and city');
    }

    if (address.pincode.length < 5) {
      throw ArgumentError('Invalid pincode');
    }

    // ✅ Validate scheduled date
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final scheduled = DateTime(
      scheduledAt.year,
      scheduledAt.month,
      scheduledAt.day,
    );

    if (scheduled.isBefore(today)) {
      throw ArgumentError('Scheduled date cannot be in the past');
    }
  }

  /// Get job by ID
  Future<Job?> getJob(String jobId) async {
    return await _firebaseService.getJob(jobId);
  }

  /// Stream job updates
  Stream<Job?> watchJob(String jobId) {
    return _firebaseService.watchJob(jobId);
  }

  /// Get all jobs for client
  Future<List<Job>> getClientJobs(String clientUid) async {
    return await _firebaseService.getClientJobs(clientUid);
  }

  /// Stream client jobs
  Stream<List<Job>> watchClientJobs(String clientUid) {
    return _firebaseService.watchClientJobs(clientUid);
  }

  /// Get jobs by status
  Future<List<Job>> getJobsByStatus(String clientUid, JobStatus status) async {
    return await _firebaseService.getClientJobsByStatus(clientUid, status);
  }

  /// Stream jobs by status
  Stream<List<Job>> watchJobsByStatus(String clientUid, JobStatus status) {
    return _firebaseService.watchClientJobsByStatus(clientUid, status);
  }

  /// Cancel job with validation
  Future<void> cancelJob(String jobId, String reason) async {
    final job = await _firebaseService.getJob(jobId);

    if (job == null) {
      throw Exception('Job not found');
    }

    if (!job.canBeCancelled) {
      throw Exception('Job cannot be cancelled in ${job.statusLabel} status');
    }

    if (reason.trim().isEmpty) {
      throw ArgumentError('Cancellation reason is required');
    }

    await _firebaseService.cancelJob(jobId, reason.trim());
  }

  /// Reschedule job with validation
  Future<void> rescheduleJob(String jobId, DateTime newScheduledAt) async {
    final job = await _firebaseService.getJob(jobId);

    if (job == null) {
      throw Exception('Job not found');
    }

    if (!job.canBeRescheduled) {
      throw Exception('Job cannot be rescheduled in ${job.statusLabel} status');
    }

    if (newScheduledAt.isBefore(DateTime.now())) {
      throw ArgumentError('Cannot reschedule to a past date');
    }

    await _firebaseService.rescheduleJob(jobId, newScheduledAt);
  }

  /// Mark job as in progress
  Future<void> startJob(String jobId) async {
    await _firebaseService.updateJobStatus(jobId, JobStatus.inProgress);
  }

  /// Mark job as completed
  Future<void> completeJob(String jobId) async {
    await _firebaseService.updateJobStatus(jobId, JobStatus.completed);
  }

  /// Get recent jobs
  Future<List<Job>> getRecentJobs(String clientUid, {int limit = 5}) async {
    return await _firebaseService.getRecentJobs(clientUid, limit: limit);
  }

  /// Stream recent jobs
  Stream<List<Job>> watchRecentJobs(String clientUid, {int limit = 5}) {
    return _firebaseService.watchRecentJobs(clientUid, limit: limit);
  }
}