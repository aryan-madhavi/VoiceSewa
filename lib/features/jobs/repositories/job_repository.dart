import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voicesewa_worker/shared/data/service_data.dart';
import 'package:voicesewa_worker/shared/models/job_model.dart';
import 'package:voicesewa_worker/shared/models/quotation_model.dart';

class JobRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _jobs    => _firestore.collection('jobs');
  CollectionReference get _workers => _firestore.collection('workers');

  // ── Haversine distance (km) ──────────────────────────────────────────────

  double _distanceKm(GeoPoint a, GeoPoint b) {
    const r = 6371.0;
    final dLat = _toRad(b.latitude - a.latitude);
    final dLon = _toRad(b.longitude - a.longitude);
    final h = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(a.latitude)) *
            cos(_toRad(b.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return 2 * r * asin(sqrt(h));
  }

  double _toRad(double deg) => deg * pi / 180;

  // ── Incoming jobs: skill match + within 5 km ────────────────────────────
  // Fetches status='requested' jobs, then filters in-memory by skill + proximity.
  // Skill match: worker stores display name "AC / Appliance Technician",
  // job stores enum key "acApplianceTechnician" — ServicesData bridges these.

  Future<List<JobModel>> fetchIncomingJobs({
    required List<String> workerSkills,
    required GeoPoint workerLocation,
    double radiusKm = 5.0,
  }) async {
    print('🔍 fetchIncomingJobs — skills: $workerSkills, '
        'location: (${workerLocation.latitude}, ${workerLocation.longitude}), '
        'radius: ${radiusKm}km');
    try {
      final snap = await _jobs
          .where('status', isEqualTo: 'requested')
          .orderBy('created_at', descending: true)
          .get();

      print('📦 fetchIncomingJobs — "requested" jobs in Firestore: ${snap.docs.length}');

      // Pre-build a set of Services enum values that match this worker's skills.
      // Worker skill = display name e.g. "AC / Appliance Technician"
      // ServicesData key = Services.acApplianceTechnician
      final matchingServices = <Services>{};
      for (final skill in workerSkills) {
        final entry = ServicesData.services.entries.firstWhere(
          (e) => (e.value[2] as String).toLowerCase().trim() ==
              skill.toLowerCase().trim(),
          orElse: () => const MapEntry(Services.handymanMasonryWork, []),
        );
        if ((entry.value as List).isNotEmpty) {
          matchingServices.add(entry.key);
        }
      }
      print('🔍 matchingServices enum set: $matchingServices');

      final results = <JobModel>[];
      for (final doc in snap.docs) {
        final job = JobModel.fromDoc(doc);
        print('  🗂  job [${job.jobId}] serviceType=${job.serviceType.name} '
            'location=${job.address.location}');

        final jobLocation = job.address.location;
        if (jobLocation == null) {
          print('     ⛔ skipped — no location on job');
          continue;
        }

        // Skill match: compare typed Services enum directly
        if (!matchingServices.contains(job.serviceType)) {
          print('     ⛔ skipped — skill mismatch. '
              'workerServices=$matchingServices vs job=${job.serviceType.name}');
          continue;
        }

        final dist = _distanceKm(workerLocation, jobLocation);
        print('     📍 distance: ${dist.toStringAsFixed(2)} km (limit: $radiusKm km)');

        if (dist > radiusKm) {
          print('     ⛔ skipped — too far (${dist.toStringAsFixed(2)} km)');
          continue;
        }

        print('     ✅ included!');
        results.add(job);
      }

      print('✅ fetchIncomingJobs — returning ${results.length} jobs');
      return results;
    } catch (e, st) {
      print('❌ fetchIncomingJobs error: $e\n$st');
      return [];
    }
  }

  // ── Applied jobs — jobs worker has submitted a quotation for ─────────────

  Future<List<JobModel>> fetchAppliedJobs(String workerUid) async {
    try {
      final workerDoc = await _workers.doc(workerUid).get();
      if (!workerDoc.exists) return [];
      final data = workerDoc.data() as Map<String, dynamic>;
      final appliedRefs = List<DocumentReference>.from(
        (data['jobs'] as Map<String, dynamic>?)?['applied'] ?? [],
      );

      final results = <JobModel>[];
      for (final ref in appliedRefs) {
        final doc = await ref.get();
        if (doc.exists) results.add(JobModel.fromDoc(doc));
      }
      return results;
    } catch (e) {
      print('❌ fetchAppliedJobs error: $e');
      return [];
    }
  }

  // ── Ongoing jobs stream ────────────────────────────────────────────────────
  // The job document has no worker_uid field, so we can't query by it.
  // Instead we watch the worker doc's jobs.confirmed ref array and fetch
  // each job, filtering to status in [scheduled, inProgress, rescheduled].

  Stream<List<JobModel>> watchOngoingJobs(String workerUid) {
    return _workers.doc(workerUid).snapshots().asyncMap((workerSnap) async {
      if (!workerSnap.exists) return <JobModel>[];
      final data = workerSnap.data() as Map<String, dynamic>;
      final confirmedRefs = List<DocumentReference>.from(
        (data['jobs'] as Map<String, dynamic>?)?['confirmed'] ?? [],
      );
      print('🔍 watchOngoingJobs — confirmed refs: ${confirmedRefs.length}');

      const ongoingStatuses = {'scheduled', 'inProgress', 'rescheduled'};
      final results = <JobModel>[];
      for (final ref in confirmedRefs) {
        final doc = await ref.get();
        if (!doc.exists) continue;
        final job = JobModel.fromDoc(doc);
        if (ongoingStatuses.contains(job.status.value)) {
          results.add(job);
        }
      }
      print('✅ watchOngoingJobs — returning ${results.length} ongoing jobs');
      return results;
    });
  }

  // ── Completed jobs stream ─────────────────────────────────────────────────
  // Same pattern — watch jobs.completed ref array on worker doc.

  Stream<List<JobModel>> watchCompletedJobs(String workerUid) {
    return _workers.doc(workerUid).snapshots().asyncMap((workerSnap) async {
      if (!workerSnap.exists) return <JobModel>[];
      final data = workerSnap.data() as Map<String, dynamic>;
      final completedRefs = List<DocumentReference>.from(
        (data['jobs'] as Map<String, dynamic>?)?['completed'] ?? [],
      );
      print('🔍 watchCompletedJobs — completed refs: ${completedRefs.length}');

      final results = <JobModel>[];
      for (final ref in completedRefs) {
        final doc = await ref.get();
        if (!doc.exists) continue;
        final job = JobModel.fromDoc(doc);
        if (job.status == JobStatusType.completed) results.add(job);
      }
      print('✅ watchCompletedJobs — returning ${results.length} completed jobs');
      return results;
    });
  }



  // ── Submit quotation ──────────────────────────────────────────────────────
  // Batch: add quotation sub-doc + set job status → 'quoted' + update worker applied list.

  Future<bool> submitQuotation({
    required String jobId,
    required QuotationModel quotation,
    required String workerUid,
  }) async {
    try {
      final batch  = _firestore.batch();
      final jobRef = _jobs.doc(jobId);

      // 1. Add quotation sub-document
      final quoRef = jobRef.collection('quotations').doc();
      batch.set(quoRef, quotation.toMap());

      // 2. Update job status → "quoted"
      batch.update(jobRef, {'status': 'quoted'});

      // 3. Add job ref to worker's applied list
      batch.update(_workers.doc(workerUid), {
        'jobs.applied': FieldValue.arrayUnion([jobRef]),
      });

      await batch.commit();
      print('✅ Quotation submitted, job $jobId status → "quoted"');
      return true;
    } catch (e) {
      print('❌ submitQuotation error: $e');
      return false;
    }
  }

  // ── Fetch this worker's quotation for a job ───────────────────────────────

  Future<QuotationModel?> fetchMyQuotation({
    required String jobId,
    required String workerUid,
  }) async {
    try {
      final snap = await _jobs
          .doc(jobId)
          .collection('quotations')
          .where('worker_uid', isEqualTo: workerUid)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      return QuotationModel.fromDoc(snap.docs.first, jobId);
    } catch (e) {
      print('❌ fetchMyQuotation error: $e');
      return null;
    }
  }

  // ── Mark job as completed ─────────────────────────────────────────────────

  Future<bool> markJobCompleted({
    required String jobId,
    required String workerUid,
  }) async {
    try {
      final jobRef    = _jobs.doc(jobId);
      final workerRef = _workers.doc(workerUid);
      final batch = _firestore.batch();

      batch.update(jobRef, {'status': 'completed'});
      batch.update(workerRef, {
        'jobs.completed': FieldValue.arrayUnion([jobRef]),
        'jobs.confirmed': FieldValue.arrayRemove([jobRef]),
      });

      await batch.commit();
      print('✅ Job $jobId marked as completed');
      return true;
    } catch (e) {
      print('❌ markJobCompleted error: $e');
      return false;
    }
  }

  // ── Fetch single job ──────────────────────────────────────────────────────

  Future<JobModel?> fetchJob(String jobId) async {
    try {
      final doc = await _jobs.doc(jobId).get();
      if (!doc.exists) return null;
      return JobModel.fromDoc(doc);
    } catch (e) {
      print('❌ fetchJob error: $e');
      return null;
    }
  }
}