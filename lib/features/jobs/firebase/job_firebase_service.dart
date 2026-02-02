import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voicesewa_client/shared/models/job_model.dart';

/// Firebase service for job operations
/// Handles all Firestore CRUD operations with offline support and real-time updates
class JobFirebaseService {
  final FirebaseFirestore _firestore;
  static const String _jobsCollection = 'jobs';
  static const String _clientsCollection = 'clients';

  JobFirebaseService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance {
    // Enable offline persistence
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  /// Collection references
  CollectionReference<Map<String, dynamic>> get _jobsRef =>
      _firestore.collection(_jobsCollection);

  CollectionReference<Map<String, dynamic>> get _clientsRef =>
      _firestore.collection(_clientsCollection);

  /// Create a new job and update client's requested array
  /// ✅ FIXED: Works offline - uses DateTime.now() instead of serverTimestamp
  Future<String> createJob(Job job) async {
    try {
      print('🆕 Creating job: ${job.serviceName}');
      print('👤 Client UID: ${job.clientUid}');
      print('📅 Scheduled for: ${job.scheduledAt}');

      // ✅ Use DateTime.now() for offline support
      final now = DateTime.now();

      // Prepare job data according to schema
      final jobData = <String, dynamic>{
        'service_type': job.serviceType.name,
        'description': job.description,
        'address': job.address.toMap(),
        'client_uid': job.clientUid,
        'created_at': Timestamp.fromDate(now), // ✅ Use DateTime.now()
        'status': job.status.value,
      };

      // ✅ Add scheduled_at if client specified when they want the job
      if (job.scheduledAt != null) {
        jobData['scheduled_at'] = Timestamp.fromDate(job.scheduledAt!);
      }

      // Create job document with auto-generated ID
      final docRef = await _jobsRef.add(jobData);
      final jobId = docRef.id;

      print('✅ Job document created with ID: $jobId');

      // Update client's services.requested array
      try {
        await _clientsRef.doc(job.clientUid).update({
          'services.requested': FieldValue.arrayUnion([docRef]),
        });
        print('✅ Client requested array updated');
      } catch (e) {
        print('⚠️ Could not update client requested array: $e');
        print('💡 Make sure client document exists');
        // Don't fail the job creation if this update fails
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
      print('📖 Fetching job: $jobId');

      // Try cache first
      final cacheSnapshot = await _jobsRef
          .doc(jobId)
          .get(const GetOptions(source: Source.cache));

      if (cacheSnapshot.exists) {
        print('✅ Job found in cache');
        final job = Job.fromMap(jobId, cacheSnapshot.data()!);

        // Fetch from server in background
        _jobsRef
            .doc(jobId)
            .get()
            .then((serverSnapshot) {
              if (serverSnapshot.exists) {
                print('🔄 Job updated from server');
              }
            })
            .catchError((e) {
              print('⚠️ Server fetch failed (offline): $e');
            });

        return job;
      }

      // Not in cache, try server
      final serverSnapshot = await _jobsRef.doc(jobId).get();

      if (serverSnapshot.exists) {
        print('✅ Job fetched from server');
        return Job.fromMap(jobId, serverSnapshot.data()!);
      }

      print('ℹ️ Job not found: $jobId');
      return null;
    } catch (e) {
      print('❌ Error fetching job: $e');
      rethrow;
    }
  }

  /// Stream job updates in real-time
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
      print('📖 Fetching jobs for client UID: $clientUid');

      final snapshot = await _jobsRef
          .where('client_uid', isEqualTo: clientUid)
          .orderBy('created_at', descending: true)
          .get();

      final jobs = snapshot.docs
          .map((doc) => Job.fromMap(doc.id, doc.data()))
          .toList();

      print('✅ Found ${jobs.length} jobs for client');
      return jobs;
    } catch (e) {
      print('❌ Error fetching client jobs: $e');
      rethrow;
    }
  }

  /// Stream client jobs in real-time
  Stream<List<Job>> watchClientJobs(String clientUid) {
    return _jobsRef
        .where('client_uid', isEqualTo: clientUid)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Job.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  /// Get jobs by status for a client
  Future<List<Job>> getClientJobsByStatus(
    String clientUid,
    JobStatus status,
  ) async {
    try {
      print('📖 Fetching ${status.value} jobs for client UID: $clientUid');

      final snapshot = await _jobsRef
          .where('client_uid', isEqualTo: clientUid)
          .where('status', isEqualTo: status.value)
          .orderBy('created_at', descending: true)
          .get();

      final jobs = snapshot.docs
          .map((doc) => Job.fromMap(doc.id, doc.data()))
          .toList();

      print('✅ Found ${jobs.length} ${status.value} jobs');
      return jobs;
    } catch (e) {
      print('❌ Error fetching jobs by status: $e');
      rethrow;
    }
  }

  /// Stream jobs by status in real-time
  Stream<List<Job>> watchClientJobsByStatus(
    String clientUid,
    JobStatus status,
  ) {
    return _jobsRef
        .where('client_uid', isEqualTo: clientUid)
        .where('status', isEqualTo: status.value)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Job.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  /// Update job status
  Future<void> updateJobStatus(
    String jobId,
    JobStatus newStatus, {
    DateTime? scheduledAt,
  }) async {
    try {
      print('🔄 Updating job $jobId status to: ${newStatus.value}');

      final updates = <String, dynamic>{'status': newStatus.value};

      if (scheduledAt != null) {
        updates['scheduled_at'] = Timestamp.fromDate(scheduledAt);
      }

      await _jobsRef.doc(jobId).update(updates);

      print('✅ Job status updated');
    } catch (e) {
      print('❌ Error updating job status: $e');
      rethrow;
    }
  }

  /// ✅ THIS is the ONLY place where finalized_quotation should be set
  /// Called when client accepts a quotation
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

      // Create reference to the quotation document
      final quotationRef = _jobsRef
          .doc(jobId)
          .collection('quotations')
          .doc(quotationId);

      // ✅ Update job with finalized quotation reference
      await _jobsRef.doc(jobId).update({
        'finalized_quotation': quotationRef,
        'status': JobStatus.scheduled.value,
        'scheduled_at': Timestamp.fromDate(scheduledAt),
      });

      print('✅ Quotation finalized');
    } catch (e) {
      print('❌ Error finalizing quotation: $e');
      rethrow;
    }
  }

  /// Reschedule job
  Future<void> rescheduleJob(String jobId, DateTime newScheduledAt) async {
    try {
      print('🔄 Rescheduling job $jobId');

      await _jobsRef.doc(jobId).update({
        'status': JobStatus.rescheduled.value,
        'scheduled_at': Timestamp.fromDate(newScheduledAt),
      });

      print('✅ Job rescheduled');
    } catch (e) {
      print('❌ Error rescheduling job: $e');
      rethrow;
    }
  }

  /// Cancel job
  Future<void> cancelJob(String jobId, String reason) async {
    try {
      print('🔄 Cancelling job $jobId');

      await _jobsRef.doc(jobId).update({'status': JobStatus.cancelled.value});

      print('✅ Job cancelled');
    } catch (e) {
      print('❌ Error cancelling job: $e');
      rethrow;
    }
  }

  /// Delete job (rarely used)
  Future<void> deleteJob(String jobId) async {
    try {
      print('🗑️ Deleting job: $jobId');
      await _jobsRef.doc(jobId).delete();
      print('✅ Job deleted');
    } catch (e) {
      print('❌ Error deleting job: $e');
      rethrow;
    }
  }

  /// Get recent jobs (for home screen)
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
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Job.fromMap(doc.id, doc.data()))
              .toList();
        });
  }
}
