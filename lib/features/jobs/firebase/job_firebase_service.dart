import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voicesewa_client/shared/models/job_model.dart';

/// Firebase service for job operations
class JobFirebaseService {
  final FirebaseFirestore _firestore;
  static const String _jobsCollection = 'jobs';
  static const String _clientsCollection = 'clients';

  JobFirebaseService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance {
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  CollectionReference<Map<String, dynamic>> get _jobsRef =>
      _firestore.collection(_jobsCollection);

  CollectionReference<Map<String, dynamic>> get _clientsRef =>
      _firestore.collection(_clientsCollection);

  /// Generate a 4-digit OTP string
  String _generateOtp() {
    final random = Random.secure();
    final otp = random.nextInt(9000) + 1000; // 1000–9999
    return otp.toString();
  }

  /// Create a new job and update client's requested array
  Future<String> createJob(Job job) async {
    try {
      print('🆕 Creating job: ${job.serviceName}');

      final now = DateTime.now();

      final jobData = <String, dynamic>{
        'service_type': job.serviceType.name,
        'description': job.description,
        'address': job.address.toMap(),
        'client_uid': job.clientUid,
        'created_at': Timestamp.fromDate(now),
        'status': job.status.value,
      };

      if (job.scheduledAt != null) {
        jobData['scheduled_at'] = Timestamp.fromDate(job.scheduledAt!);
      }

      final docRef = await _jobsRef.add(jobData);
      final jobId = docRef.id;
      print('✅ Job created with ID: $jobId');

      try {
        await _clientsRef.doc(job.clientUid).update({
          'services.requested': FieldValue.arrayUnion([docRef]),
        });
      } catch (e) {
        print('⚠️ Could not update client requested array: $e');
      }

      return jobId;
    } catch (e) {
      print('❌ Error creating job: $e');
      rethrow;
    }
  }

  /// Get job by ID
  Future<Job?> getJob(String jobId) async {
    try {
      final cacheSnapshot = await _jobsRef
          .doc(jobId)
          .get(const GetOptions(source: Source.cache));

      if (cacheSnapshot.exists) {
        final job = Job.fromMap(jobId, cacheSnapshot.data()!);
        _jobsRef.doc(jobId).get().then((_) {}).catchError((e) {
          print('⚠️ Server fetch failed (offline): $e');
        });
        return job;
      }

      final serverSnapshot = await _jobsRef.doc(jobId).get();
      if (serverSnapshot.exists) {
        return Job.fromMap(jobId, serverSnapshot.data()!);
      }
      return null;
    } catch (e) {
      print('❌ Error fetching job: $e');
      rethrow;
    }
  }

  /// Stream job updates
  Stream<Job?> watchJob(String jobId) {
    return _jobsRef.doc(jobId).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return Job.fromMap(jobId, snapshot.data()!);
      }
      return null;
    });
  }

  /// Get jobs by client UID
  Future<List<Job>> getClientJobs(String clientUid) async {
    try {
      final snapshot = await _jobsRef
          .where('client_uid', isEqualTo: clientUid)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Job.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('❌ Error fetching client jobs: $e');
      rethrow;
    }
  }

  /// Stream client jobs
  Stream<List<Job>> watchClientJobs(String clientUid) {
    return _jobsRef
        .where('client_uid', isEqualTo: clientUid)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Job.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Get jobs by status
  Future<List<Job>> getClientJobsByStatus(
    String clientUid,
    JobStatus status,
  ) async {
    try {
      final snapshot = await _jobsRef
          .where('client_uid', isEqualTo: clientUid)
          .where('status', isEqualTo: status.value)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Job.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('❌ Error fetching jobs by status: $e');
      rethrow;
    }
  }

  /// Stream jobs by status
  Stream<List<Job>> watchClientJobsByStatus(
    String clientUid,
    JobStatus status,
  ) {
    return _jobsRef
        .where('client_uid', isEqualTo: clientUid)
        .where('status', isEqualTo: status.value)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Job.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Update job status
  Future<void> updateJobStatus(
    String jobId,
    JobStatus newStatus, {
    DateTime? scheduledAt,
  }) async {
    try {
      final updates = <String, dynamic>{'status': newStatus.value};
      if (scheduledAt != null) {
        updates['scheduled_at'] = Timestamp.fromDate(scheduledAt);
      }
      await _jobsRef.doc(jobId).update(updates);
    } catch (e) {
      print('❌ Error updating job status: $e');
      rethrow;
    }
  }

  /// Finalize quotation — called when client accepts a quotation.
  /// ✅ Generates a 4-digit OTP and stores worker details on the job document.
  Future<void> finalizeQuotation(
    String jobId,
    String quotationId,
    String workerUid,
    String workerName,
    double workerRating,
    String estimatedCost,
    String estimatedTime,
    DateTime scheduledAt,
  ) async {
    try {
      print('🔄 Finalizing quotation for job $jobId');

      final quotationRef = _jobsRef
          .doc(jobId)
          .collection('quotations')
          .doc(quotationId);

      // ✅ Generate 4-digit OTP
      final otp = _generateOtp();
      print('🔑 Generated OTP: $otp for job $jobId');

      // ✅ Parse estimatedCost string (e.g. "₹500" or "500") to number for schema
      final amountString = estimatedCost.replaceAll(RegExp(r'[^0-9.]'), '');
      final amountNumber = double.tryParse(amountString);

      await _jobsRef.doc(jobId).update({
        'finalized_quotation': quotationRef,
        // ✅ Store as number (schema: finalized_quotation_amount: number | null)
        'finalized_quotation_amount': amountNumber,
        'status': JobStatus.scheduled.value,
        'scheduled_at': Timestamp.fromDate(scheduledAt),
        // ✅ Store worker details on job document (schema: worker_name, worker_rating)
        'worker_name': workerName,
        'worker_rating': workerRating,
        // ✅ Store OTP as string (schema: otp: string | null)
        'otp': otp,
      });

      print('✅ Quotation finalized with OTP');
    } catch (e) {
      print('❌ Error finalizing quotation: $e');
      rethrow;
    }
  }

  /// Reschedule job
  Future<void> rescheduleJob(String jobId, DateTime newScheduledAt) async {
    try {
      await _jobsRef.doc(jobId).update({
        'status': JobStatus.rescheduled.value,
        'scheduled_at': Timestamp.fromDate(newScheduledAt),
      });
    } catch (e) {
      print('❌ Error rescheduling job: $e');
      rethrow;
    }
  }

  /// Cancel job
  Future<void> cancelJob(String jobId, String reason) async {
    try {
      await _jobsRef.doc(jobId).update({'status': JobStatus.cancelled.value});
    } catch (e) {
      print('❌ Error cancelling job: $e');
      rethrow;
    }
  }

  /// Delete job
  Future<void> deleteJob(String jobId) async {
    try {
      await _jobsRef.doc(jobId).delete();
    } catch (e) {
      print('❌ Error deleting job: $e');
      rethrow;
    }
  }

  /// Submit client feedback (rating + comment) for a completed job
  Future<void> submitClientFeedback(
    String jobId,
    double rating,
    String comment,
  ) async {
    try {
      print('⭐ Submitting client feedback for job $jobId');
      await _jobsRef.doc(jobId).update({
        'client_feedback': {
          'rating': rating,
          'comment': comment,
          'created_at': Timestamp.now(),
        },
      });
      print('✅ Client feedback submitted');
    } catch (e) {
      print('❌ Error submitting client feedback: $e');
      rethrow;
    }
  }

  /// Get recent jobs
  Future<List<Job>> getRecentJobs(String clientUid, {int limit = 5}) async {
    try {
      final snapshot = await _jobsRef
          .where('client_uid', isEqualTo: clientUid)
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => Job.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('❌ Error fetching recent jobs: $e');
      rethrow;
    }
  }

  /// Stream recent jobs
  Stream<List<Job>> watchRecentJobs(String clientUid, {int limit = 5}) {
    return _jobsRef
        .where('client_uid', isEqualTo: clientUid)
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Job.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }
}
