import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voicesewa_worker/shared/data/service_data.dart';
import 'package:voicesewa_worker/shared/models/job_model.dart';
import 'package:voicesewa_worker/shared/models/quotation_model.dart';

class JobRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _jobs => _firestore.collection('jobs');
  CollectionReference get _workers => _firestore.collection('workers');
  CollectionReference get _clients => _firestore.collection('clients');

  // ── Cache-first document fetch ────────────────────────────────────────────
  // Tries Firestore local cache first, falls back to server.
  // This makes the app work offline and shows data instantly on repeat opens.

  Future<DocumentSnapshot> _getDoc(DocumentReference ref) async {
    try {
      return await ref.get(const GetOptions(source: Source.cache));
    } catch (_) {
      return await ref.get(const GetOptions(source: Source.server));
    }
  }

  // ── Parallel document fetch ────────────────────────────────────────────────
  // Resolves all refs simultaneously instead of one-by-one.
  // 10 serial awaits (≈10s) → 10 parallel awaits (≈1s, limited by slowest).

  Future<List<JobModel>> _fetchJobRefs(List<DocumentReference> refs) async {
    if (refs.isEmpty) return [];
    final docs = await Future.wait(refs.map(_getDoc));
    return docs.where((d) => d.exists).map((d) => JobModel.fromDoc(d)).toList();
  }

  // ── Haversine distance (km) ────────────────────────────────────────────────

  double _distanceKm(GeoPoint a, GeoPoint b) {
    const r = 6371.0;
    final dLat = _toRad(b.latitude - a.latitude);
    final dLon = _toRad(b.longitude - a.longitude);
    final h =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(a.latitude)) *
            cos(_toRad(b.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return 2 * r * asin(sqrt(h));
  }

  double _toRad(double deg) => deg * pi / 180;

  // ── Incoming jobs ─────────────────────────────────────────────────────────
  // Key changes vs original:
  //   • Queries per service_type individually (uses Firestore index on
  //     [service_type, status]) instead of scanning the whole collection.
  //   • Filters declined IDs in Dart — no extra round-trips.
  //   • Fetches applied (quoted) refs in parallel.
  //   • Removes orderBy from Firestore — sorts in memory instead, eliminating
  //     composite index dependency and the slow index-build cold start.
  //   • Limits each per-service query to 50 docs to bound scan cost.

  Future<List<JobModel>> fetchIncomingJobs({
    required List<String> workerSkills,
    required GeoPoint workerLocation,
    required String workerUid,
    double radiusKm = 5.0,
    int limitPerService = 50,
  }) async {
    try {
      // Map display-name skills → Services enum values
      final matchingServices = <Services>{};
      for (final skill in workerSkills) {
        final entry = ServicesData.services.entries.firstWhere(
          (e) =>
              (e.value[2] as String).toLowerCase().trim() ==
              skill.toLowerCase().trim(),
          orElse: () => const MapEntry(Services.handymanMasonryWork, []),
        );
        if ((entry.value as List).isNotEmpty) matchingServices.add(entry.key);
      }
      if (matchingServices.isEmpty) return [];

      // Fetch worker doc once (cache-first)
      final workerDoc = await _getDoc(_workers.doc(workerUid));
      final workerData = workerDoc.data() as Map<String, dynamic>? ?? {};
      final jobsMap = workerData['jobs'] as Map<String, dynamic>? ?? {};

      final declinedIds = List<DocumentReference>.from(
        jobsMap['declined'] ?? [],
      ).map((r) => r.id).toSet();
      final appliedRefs = List<DocumentReference>.from(
        jobsMap['applied'] ?? [],
      );

      // 1. Query requested jobs — one query per matched service in parallel.
      //    This targets the [service_type + status] composite index and avoids
      //    scanning unrelated service documents entirely.
      final serviceQueries = matchingServices.map((service) {
        return _jobs
            .where('service_type', isEqualTo: service.name)
            .where('status', isEqualTo: 'requested')
            .limit(limitPerService)
            .get(const GetOptions(source: Source.serverAndCache));
      });

      final serviceSnaps = await Future.wait(serviceQueries);

      final seen = <String>{};
      final results = <JobModel>[];

      for (final snap in serviceSnaps) {
        for (final doc in snap.docs) {
          if (seen.contains(doc.id)) continue;
          if (declinedIds.contains(doc.id)) continue;
          final job = JobModel.fromDoc(doc);
          final loc = job.address.location;
          if (loc == null) continue;
          if (_distanceKm(workerLocation, loc) > radiusKm) continue;
          seen.add(doc.id);
          results.add(job);
        }
      }

      // 2. Fetch applied (quoted) jobs in parallel
      if (appliedRefs.isNotEmpty) {
        final appliedDocs = await Future.wait(appliedRefs.map(_getDoc));
        for (final doc in appliedDocs) {
          if (!doc.exists) continue;
          final job = JobModel.fromDoc(doc);
          if (job.status == JobStatusType.quoted && !seen.contains(job.jobId)) {
            seen.add(job.jobId);
            results.add(job);
          }
        }
      }

      // Sort in memory — no Firestore index needed
      results.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(0);
        final bDate = b.createdAt ?? DateTime(0);
        return bDate.compareTo(aDate); // newest first
      });

      print(
        '✅ fetchIncomingJobs — ${results.length} jobs '
        '(${results.where((j) => j.isQuoted).length} quoted)',
      );
      return results;
    } catch (e, st) {
      print('❌ fetchIncomingJobs error: $e\n$st');
      return [];
    }
  }

  // ── Applied jobs ──────────────────────────────────────────────────────────
  // Parallel fetch — was serial loop.

  Future<List<JobModel>> fetchAppliedJobs(String workerUid) async {
    try {
      final workerDoc = await _getDoc(_workers.doc(workerUid));
      if (!workerDoc.exists) return [];
      final data = workerDoc.data() as Map<String, dynamic>;
      final appliedRefs = List<DocumentReference>.from(
        (data['jobs'] as Map<String, dynamic>?)?['applied'] ?? [],
      );
      return _fetchJobRefs(appliedRefs);
    } catch (e) {
      print('❌ fetchAppliedJobs error: $e');
      return [];
    }
  }

  // ── Ongoing jobs stream ────────────────────────────────────────────────────
  // Was: asyncMap with serial for-loop → now parallel Future.wait inside asyncMap.
  // asyncMap is kept because we genuinely need live updates when the worker doc
  // changes (new job confirmed, job moves to completed etc.), but the inner
  // fetches are now all parallel.

  Stream<List<JobModel>> watchOngoingJobs(String workerUid) {
    const ongoingStatuses = {'scheduled', 'inProgress', 'rescheduled'};
    return _workers.doc(workerUid).snapshots().asyncMap((snap) async {
      if (!snap.exists) return <JobModel>[];
      final data = snap.data() as Map<String, dynamic>;
      final confirmedRefs = List<DocumentReference>.from(
        (data['jobs'] as Map<String, dynamic>?)?['confirmed'] ?? [],
      );
      if (confirmedRefs.isEmpty) return <JobModel>[];

      // Parallel fetch — all confirmed jobs at once
      final jobs = await _fetchJobRefs(confirmedRefs);
      return jobs
          .where((j) => ongoingStatuses.contains(j.status.value))
          .toList()
        ..sort((a, b) {
          final aDate = a.scheduledAt ?? a.createdAt ?? DateTime(0);
          final bDate = b.scheduledAt ?? b.createdAt ?? DateTime(0);
          return bDate.compareTo(aDate);
        });
    });
  }

  // ── Completed jobs stream ─────────────────────────────────────────────────
  // Parallel fetch + lazy pagination: only fetches the most recent 20 by
  // slicing refs in reverse. Older ones load via loadMoreCompleted().

  static const int _completedPageSize = 20;

  Stream<List<JobModel>> watchCompletedJobs(String workerUid) {
    return _workers.doc(workerUid).snapshots().asyncMap((snap) async {
      if (!snap.exists) return <JobModel>[];
      final data = snap.data() as Map<String, dynamic>;
      final completedRefs = List<DocumentReference>.from(
        (data['jobs'] as Map<String, dynamic>?)?['completed'] ?? [],
      );
      if (completedRefs.isEmpty) return <JobModel>[];

      // Only fetch the latest _completedPageSize refs (refs are append-order)
      final recentRefs = completedRefs.length > _completedPageSize
          ? completedRefs.sublist(completedRefs.length - _completedPageSize)
          : completedRefs;

      final jobs = await _fetchJobRefs(recentRefs);
      return jobs.where((j) => j.status == JobStatusType.completed).toList()
        ..sort((a, b) {
          final aDate = a.createdAt ?? DateTime(0);
          final bDate = b.createdAt ?? DateTime(0);
          return bDate.compareTo(aDate);
        });
    });
  }

  /// Load an older page of completed jobs (call when user scrolls to bottom).
  /// [alreadyLoadedCount] = number already shown; returns the next page.
  Future<List<JobModel>> loadMoreCompleted({
    required String workerUid,
    required int alreadyLoadedCount,
  }) async {
    try {
      final workerDoc = await _getDoc(_workers.doc(workerUid));
      if (!workerDoc.exists) return [];
      final data = workerDoc.data() as Map<String, dynamic>;
      final completedRefs = List<DocumentReference>.from(
        (data['jobs'] as Map<String, dynamic>?)?['completed'] ?? [],
      );
      if (completedRefs.isEmpty) return [];

      final totalRefs = completedRefs.length;
      final endIndex = totalRefs - alreadyLoadedCount;
      if (endIndex <= 0) return []; // nothing more to load

      final startIndex = (endIndex - _completedPageSize).clamp(0, endIndex);
      final pageRefs = completedRefs.sublist(startIndex, endIndex);

      final jobs = await _fetchJobRefs(pageRefs);
      return jobs.where((j) => j.status == JobStatusType.completed).toList()
        ..sort((a, b) {
          final aDate = a.createdAt ?? DateTime(0);
          final bDate = b.createdAt ?? DateTime(0);
          return bDate.compareTo(aDate);
        });
    } catch (e) {
      print('❌ loadMoreCompleted error: $e');
      return [];
    }
  }

  // ── Withdrawn jobs stream ─────────────────────────────────────────────────
  // Parallel fetch replacing serial loop.

  Stream<List<JobModel>> watchWithdrawnJobs(String workerUid) {
    return _workers.doc(workerUid).snapshots().asyncMap((snap) async {
      if (!snap.exists) return <JobModel>[];
      final data = snap.data() as Map<String, dynamic>;
      final declinedRefs = List<DocumentReference>.from(
        (data['jobs'] as Map<String, dynamic>?)?['declined'] ?? [],
      );
      return _fetchJobRefs(declinedRefs);
    });
  }

  // ── Declined jobs ─────────────────────────────────────────────────────────
  // Parallel fetch replacing serial loop.

  Future<List<JobModel>> fetchDeclinedJobs(String workerUid) async {
    try {
      final workerDoc = await _getDoc(_workers.doc(workerUid));
      if (!workerDoc.exists) return [];
      final data = workerDoc.data() as Map<String, dynamic>;
      final declinedRefs = List<DocumentReference>.from(
        (data['jobs'] as Map<String, dynamic>?)?['declined'] ?? [],
      );
      return _fetchJobRefs(declinedRefs);
    } catch (e) {
      print('❌ fetchDeclinedJobs error: $e');
      return [];
    }
  }

  // ── Submit quotation ──────────────────────────────────────────────────────

  Future<bool> submitQuotation({
    required String jobId,
    required QuotationModel quotation,
    required String workerUid,
  }) async {
    try {
      final batch = _firestore.batch();
      final jobRef = _jobs.doc(jobId);
      final quoRef = jobRef.collection('quotations').doc();
      batch.set(quoRef, quotation.toMap());
      batch.update(jobRef, {'status': 'quoted'});
      batch.update(_workers.doc(workerUid), {
        'jobs.applied': FieldValue.arrayUnion([jobRef]),
      });
      await batch.commit();
      return true;
    } catch (e) {
      print('❌ submitQuotation error: $e');
      return false;
    }
  }

  // ── Update quotation ──────────────────────────────────────────────────────

  Future<bool> updateQuotation({
    required String jobId,
    required String quotationId,
    required QuotationModel quotation,
  }) async {
    try {
      final quoRef = _jobs.doc(jobId).collection('quotations').doc(quotationId);
      final snap = await quoRef.get();
      if (!snap.exists) return false;
      if ((snap.data() as Map)['viewed_by_client'] == true) return false;
      await quoRef.update({
        'estimated_cost': quotation.estimatedCost,
        'estimated_time': quotation.estimatedTime,
        'description': quotation.description,
        'notes': quotation.notes,
        'availability': quotation.availability,
        'price_breakdown': quotation.priceBreakdown,
        'updated_at': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('❌ updateQuotation error: $e');
      return false;
    }
  }

  // ── Withdraw quotation ────────────────────────────────────────────────────

  Future<bool> withdrawQuotation({
    required String jobId,
    required String quotationId,
    required String workerUid,
    required String reason,
  }) async {
    try {
      final jobRef = _jobs.doc(jobId);
      final quoRef = jobRef.collection('quotations').doc(quotationId);
      final batch = _firestore.batch();
      batch.update(quoRef, {
        'status': 'withdrawn',
        'withdrawn_at': FieldValue.serverTimestamp(),
        'withdrawal_reason': reason,
      });
      batch.update(_workers.doc(workerUid), {
        'jobs.declined': FieldValue.arrayUnion([jobRef]),
        'jobs.applied': FieldValue.arrayRemove([jobRef]),
      });
      await batch.commit();
      return true;
    } catch (e) {
      print('❌ withdrawQuotation error: $e');
      return false;
    }
  }

  // ── Fetch worker's quotation for a job ────────────────────────────────────

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

  // ── Decline incoming job ──────────────────────────────────────────────────

  Future<bool> declineJob({
    required String jobId,
    required String workerUid,
  }) async {
    try {
      await _workers.doc(workerUid).update({
        'jobs.declined': FieldValue.arrayUnion([_jobs.doc(jobId)]),
      });
      return true;
    } catch (e) {
      print('❌ declineJob error: $e');
      return false;
    }
  }

  // ── Fetch client phone ────────────────────────────────────────────────────

  Future<String?> fetchClientPhone(String clientUid) async {
    try {
      final doc = await _getDoc(_clients.doc(clientUid));
      if (!doc.exists) return null;
      return (doc.data() as Map<String, dynamic>)['phone'] as String?;
    } catch (e) {
      print('❌ fetchClientPhone error: $e');
      return null;
    }
  }

  // ── Verify OTP ────────────────────────────────────────────────────────────

  Future<bool> verifyOtp({
    required String jobId,
    required String enteredOtp,
  }) async {
    try {
      final doc = await _jobs.doc(jobId).get();
      if (!doc.exists) return false;
      final stored = (doc.data() as Map<String, dynamic>)['otp'] as String?;
      return stored != null && stored == enteredOtp;
    } catch (e) {
      print('❌ verifyOtp error: $e');
      return false;
    }
  }

  // ── Start job ─────────────────────────────────────────────────────────────

  Future<bool> startJob({required String jobId}) async {
    try {
      await _jobs.doc(jobId).update({'status': 'inProgress'});
      return true;
    } catch (e) {
      print('❌ startJob error: $e');
      return false;
    }
  }

  // ── Save bill and complete ────────────────────────────────────────────────

  Future<bool> saveBillAndComplete({
    required String jobId,
    required String workerUid,
    required JobBill bill,
  }) async {
    try {
      final jobRef = _jobs.doc(jobId);
      final workerRef = _workers.doc(workerUid);
      final batch = _firestore.batch();
      batch.update(jobRef, {'status': 'completed', 'bill': bill.toMap()});
      batch.update(workerRef, {
        'jobs.completed': FieldValue.arrayUnion([jobRef]),
        'jobs.confirmed': FieldValue.arrayRemove([jobRef]),
      });
      await batch.commit();
      return true;
    } catch (e) {
      print('❌ saveBillAndComplete error: $e');
      return false;
    }
  }

  // ── Mark job completed (legacy, no bill) ─────────────────────────────────

  Future<bool> markJobCompleted({
    required String jobId,
    required String workerUid,
  }) async {
    try {
      final jobRef = _jobs.doc(jobId);
      final workerRef = _workers.doc(workerUid);
      final batch = _firestore.batch();
      batch.update(jobRef, {'status': 'completed'});
      batch.update(workerRef, {
        'jobs.completed': FieldValue.arrayUnion([jobRef]),
        'jobs.confirmed': FieldValue.arrayRemove([jobRef]),
      });
      await batch.commit();
      return true;
    } catch (e) {
      print('❌ markJobCompleted error: $e');
      return false;
    }
  }

  // ── Save worker feedback ──────────────────────────────────────────────────

  Future<bool> saveWorkerFeedback({
    required String jobId,
    required WorkerFeedback feedback,
  }) async {
    try {
      await _jobs.doc(jobId).update({'worker_feedback': feedback.toMap()});
      return true;
    } catch (e) {
      print('❌ saveWorkerFeedback error: $e');
      return false;
    }
  }

  // ── Chat: stream messages ─────────────────────────────────────────────────

  Stream<QuerySnapshot> watchMessages(String jobId) {
    return _jobs
        .doc(jobId)
        .collection('messages')
        .orderBy('sent_at', descending: false)
        .snapshots();
  }

  Future<bool> sendMessage({
    required String jobId,
    required String senderUid,
    required String senderName,
    required String text,
    required bool isWorker,
  }) async {
    try {
      await _jobs.doc(jobId).collection('messages').add({
        'sender_uid': senderUid,
        'sender_name': senderName,
        'text': text,
        'is_worker': isWorker,
        'sent_at': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('❌ sendMessage error: $e');
      return false;
    }
  }

  // ── Fetch / watch single job ──────────────────────────────────────────────

  Future<JobModel?> fetchJob(String jobId) async {
    try {
      final doc = await _getDoc(_jobs.doc(jobId));
      if (!doc.exists) return null;
      return JobModel.fromDoc(doc);
    } catch (e) {
      print('❌ fetchJob error: $e');
      return null;
    }
  }

  Stream<JobModel?> watchJob(String jobId) {
    return _jobs.doc(jobId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return JobModel.fromDoc(snap);
    });
  }
}
