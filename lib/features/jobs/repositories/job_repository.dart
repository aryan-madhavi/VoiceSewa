import 'dart:async';
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

  // ── Smart document fetch ──────────────────────────────────────────────────
  // Strategy: try server first (fresh data), fall back to cache if offline/error.
  // This ensures:
  //   • Online  → always gets the latest status (fixes the scheduled job bug)
  //   • Offline → gracefully serves cached data instead of crashing
  //
  // Unlike the old cache-first approach, this never serves a stale status
  // (e.g. showing "quoted" when the job is already "scheduled").

  Future<DocumentSnapshot> _getDoc(DocumentReference ref) async {
    try {
      // 1st attempt: live server data
      return await ref.get(const GetOptions(source: Source.server));
    } catch (_) {
      // Offline or network error → fall back to local cache
      try {
        return await ref.get(const GetOptions(source: Source.cache));
      } catch (e) {
        rethrow; // Nothing we can do — bubble up
      }
    }
  }

  // ── Smart query fetch ─────────────────────────────────────────────────────
  // Same server-first / cache-fallback strategy for collection queries.

  Future<QuerySnapshot> _getQuery(Query query) async {
    try {
      return await query.get(const GetOptions(source: Source.server));
    } catch (_) {
      return await query.get(const GetOptions(source: Source.cache));
    }
  }

  // ── Parallel document fetch ───────────────────────────────────────────────
  // Resolves all refs simultaneously using the smart _getDoc above.

  Future<List<JobModel>> _fetchJobRefs(List<DocumentReference> refs) async {
    if (refs.isEmpty) return [];
    final docs = await Future.wait(refs.map(_getDoc));
    return docs.where((d) => d.exists).map((d) => JobModel.fromDoc(d)).toList();
  }

  // ── Combine multiple job doc streams — no external packages ─────────────
  // Works by keeping the latest snapshot from each job ref in a fixed-size list.
  // Any time one job doc changes, the full merged list is re-emitted.
  // Uses only dart:async — no rxdart needed.

  Stream<List<JobModel?>> _combineJobStreams(
    List<Stream<JobModel?>> streams,
  ) {
    if (streams.isEmpty) return Stream.value([]);
    if (streams.length == 1) return streams.first.map((j) => [j]);

    final controller = StreamController<List<JobModel?>>();
    final latest = List<JobModel?>.filled(streams.length, null);
    final received = List<bool>.filled(streams.length, false);
    final subs = <StreamSubscription>[];
    int receivedCount = 0;

    for (int i = 0; i < streams.length; i++) {
      final index = i;
      final sub = streams[index].listen(
        (job) {
          if (!received[index]) {
            received[index] = true;
            receivedCount++;
          }
          latest[index] = job;
          // Only emit once every stream has produced at least one value
          if (receivedCount == streams.length) {
            if (!controller.isClosed) controller.add(List.of(latest));
          }
        },
        onError: (e) {
          if (!controller.isClosed) controller.addError(e);
        },
      );
      subs.add(sub);
    }

    controller.onCancel = () {
      for (final s in subs) s.cancel();
    };

    return controller.stream;
  }

  // ── Haversine distance (km) ───────────────────────────────────────────────

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
  // Queries per service_type individually using server-first fetch.
  // Applied (quoted) jobs are also refreshed from server so their status
  // is always current.

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
      if (matchingServices.isEmpty) {
        print('⚠️ fetchIncomingJobs — no matching services for skills: $workerSkills');
        return [];
      }

      // Fetch worker doc (server-first so declined/applied lists are fresh)
      final workerDoc = await _getDoc(_workers.doc(workerUid));
      final workerData = workerDoc.data() as Map<String, dynamic>? ?? {};
      final jobsMap = workerData['jobs'] as Map<String, dynamic>? ?? {};

      final declinedIds = List<DocumentReference>.from(
        jobsMap['declined'] ?? [],
      ).map((r) => r.id).toSet();
      final appliedRefs = List<DocumentReference>.from(
        jobsMap['applied'] ?? [],
      );

      // IDs of jobs this worker has already quoted on.
      // Used below to decide whether to show a job as "open" or "quoted".
      final appliedIds = appliedRefs.map((r) => r.id).toSet();

      // 1. Query both 'requested' AND 'quoted' jobs per service in parallel.
      //
      // WHY both statuses:
      //   'requested' → no worker has quoted yet.
      //   'quoted'    → at least one OTHER worker has quoted (client sees replies),
      //                 but the job is still open for more workers to quote on.
      //
      // We fetch both so Worker B can still see and apply to a job that
      // Worker A has already quoted on.
      const openStatuses = ['requested', 'quoted'];
      final serviceQueries = [
        for (final service in matchingServices)
          for (final status in openStatuses)
            _getQuery(
              _jobs
                  .where('service_type', isEqualTo: service.name)
                  .where('status', isEqualTo: status)
                  .limit(limitPerService),
            ),
      ];

      final serviceSnaps = await Future.wait(serviceQueries);

      final seen = <String>{};
      final results = <JobModel>[];

      for (final snap in serviceSnaps) {
        for (final doc in snap.docs) {
          if (seen.contains(doc.id)) continue;
          if (declinedIds.contains(doc.id)) continue;

          JobModel job = JobModel.fromDoc(doc);
          final loc = job.address.location;
          if (loc == null) continue;
          if (_distanceKm(workerLocation, loc) > radiusKm) continue;

          // ── Display override ──────────────────────────────────────────────
          // If Firestore status == 'quoted' but THIS worker hasn't applied yet,
          // show it locally as 'requested' (open/new) so:
          //   • It appears under the "New" chip, not "Quoted"
          //   • The worker knows it's still available to quote on
          //   • The client app is unaffected — Firestore is never touched
          //
          // If THIS worker HAS applied → keep status as 'quoted' so it shows
          // correctly under their "Quoted" chip.
          if (job.status == JobStatusType.quoted &&
              !appliedIds.contains(job.jobId)) {
            job = job.copyWith(status: JobStatusType.requested);
          }

          seen.add(job.jobId);
          results.add(job);
        }
      }

      // 2. Fetch this worker's own applied (quoted) jobs — server-first.
      // These are jobs where the worker HAS submitted a quotation.
      // We keep their real 'quoted' status so they show under the "Quoted" chip.
      if (appliedRefs.isNotEmpty) {
        final appliedDocs = await Future.wait(appliedRefs.map(_getDoc));
        for (final doc in appliedDocs) {
          if (!doc.exists) continue;
          final job = JobModel.fromDoc(doc);
          // Only add if not already in results (dedup) and still open
          if (!seen.contains(job.jobId) &&
              (job.status == JobStatusType.quoted ||
               job.status == JobStatusType.requested)) {
            seen.add(job.jobId);
            results.add(job); // real status kept — worker knows they quoted
          }
        }
      }

      results.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(0);
        final bDate = b.createdAt ?? DateTime(0);
        return bDate.compareTo(aDate);
      });

      print(
        '✅ fetchIncomingJobs — ${results.length} jobs '
        '(${results.where((j) => j.isQuoted).length} quoted by this worker)',
      );
      return results;
    } catch (e, st) {
      print('❌ fetchIncomingJobs error: $e\n$st');
      return [];
    }
  }

  // ── Applied jobs ──────────────────────────────────────────────────────────

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

  // ── Ongoing jobs stream ───────────────────────────────────────────────────
  // Two-level real-time listening — no external packages:
  //   Level 1 — worker doc snapshots() → detects when confirmed[] ref list changes.
  //   Level 2 — each job ref snapshots() → detects field changes on job docs.
  //
  // Uses _watchJobRefs() which manages individual job streams via a
  // StreamController and re-emits whenever any job doc changes.

  Stream<List<JobModel>> watchOngoingJobs(String workerUid) {
    const ongoingStatuses = {'scheduled', 'inProgress', 'rescheduled'};
    return _watchWorkerJobRefs(
      workerUid: workerUid,
      refsKey: 'confirmed',
      filter: (jobs) => jobs
          .where((j) => ongoingStatuses.contains(j.status.value))
          .toList()
        ..sort((a, b) {
          final aDate = a.scheduledAt ?? a.createdAt ?? DateTime(0);
          final bDate = b.scheduledAt ?? b.createdAt ?? DateTime(0);
          return bDate.compareTo(aDate);
        }),
    );
  }

  // ── Completed jobs stream ─────────────────────────────────────────────────

  static const int _completedPageSize = 20;

  Stream<List<JobModel>> watchCompletedJobs(String workerUid) {
    return _watchWorkerJobRefs(
      workerUid: workerUid,
      refsKey: 'completed',
      pageSize: _completedPageSize,
      filter: (jobs) => jobs
          .where((j) => j.status == JobStatusType.completed)
          .toList()
        ..sort((a, b) {
          final aDate = a.createdAt ?? DateTime(0);
          final bDate = b.createdAt ?? DateTime(0);
          return bDate.compareTo(aDate);
        }),
    );
  }

  // ── Load more completed jobs (lazy pagination) ────────────────────────────

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
      if (endIndex <= 0) return [];

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

  Stream<List<JobModel>> watchWithdrawnJobs(String workerUid) {
    return _watchWorkerJobRefs(
      workerUid: workerUid,
      refsKey: 'declined',
      filter: (jobs) => jobs,
    );
  }

  // ── Master real-time ref-list watcher ────────────────────────────────────
  // Watches a worker doc's job ref array (confirmed/completed/declined) and
  // streams each referenced job doc via snapshots() — pure dart:async only.
  //
  // When worker doc changes (refs added/removed) → cancels old job subscriptions,
  // starts fresh ones for the new ref list.
  // When any job doc field changes → immediately re-emits the full filtered list.
  //
  // This is the same pattern Firestore uses internally for collection queries —
  // just applied manually to a ref array.

  Stream<List<JobModel>> _watchWorkerJobRefs({
    required String workerUid,
    required String refsKey,
    required List<JobModel> Function(List<JobModel>) filter,
    int? pageSize,
  }) {
    // Outer controller — what the UI listens to
    final outerController = StreamController<List<JobModel>>();

    // Subscription to the worker doc
    StreamSubscription? workerSub;

    // Inner subscriptions to individual job docs (reset when refs change)
    final List<StreamSubscription> jobSubs = [];

    void cancelJobSubs() {
      for (final s in jobSubs) s.cancel();
      jobSubs.clear();
    }

    workerSub = _workers.doc(workerUid).snapshots().listen(
      (workerSnap) {
        // Worker doc changed — cancel old job listeners and start fresh
        cancelJobSubs();

        if (!workerSnap.exists) {
          if (!outerController.isClosed) outerController.add([]);
          return;
        }

        final data = workerSnap.data() as Map<String, dynamic>;
        var refs = List<DocumentReference>.from(
          (data['jobs'] as Map<String, dynamic>?)?[refsKey] ?? [],
        );

        if (refs.isEmpty) {
          if (!outerController.isClosed) outerController.add([]);
          return;
        }

        // Apply pagination if needed (completed jobs)
        if (pageSize != null && refs.length > pageSize) {
          refs = refs.sublist(refs.length - pageSize);
        }

        // latest[i] holds the most recent snapshot for each ref
        final latest = List<JobModel?>.filled(refs.length, null);
        final received = List<bool>.filled(refs.length, false);
        int receivedCount = 0;

        for (int i = 0; i < refs.length; i++) {
          final index = i;
          final sub = refs[index].snapshots().listen(
            (docSnap) {
              if (!docSnap.exists) {
                latest[index] = null;
              } else {
                latest[index] = JobModel.fromDoc(docSnap);
              }

              if (!received[index]) {
                received[index] = true;
                receivedCount++;
              }

              // Only emit once every job has produced its first snapshot
              if (receivedCount == refs.length) {
                final jobs = latest.whereType<JobModel>().toList();
                if (!outerController.isClosed) {
                  outerController.add(filter(jobs));
                }
              }
            },
            onError: (e) {
              if (!outerController.isClosed) outerController.addError(e);
            },
          );
          jobSubs.add(sub);
        }
      },
      onError: (e) {
        if (!outerController.isClosed) outerController.addError(e);
      },
    );

    outerController.onCancel = () {
      workerSub?.cancel();
      cancelJobSubs();
    };

    return outerController.stream;
  }

  // ── Declined jobs ─────────────────────────────────────────────────────────

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
      // ✅ Do NOT change job status here — it must stay 'requested' so other
      // workers can still discover and apply to this job.
      // Status only changes to 'scheduled' when the CLIENT accepts a quotation
      // (handled by the client app's finalizeQuotation).
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
      // Always fetch from server to check viewed_by_client accurately
      final snap = await quoRef.get(const GetOptions(source: Source.server));
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
      final snap = await _getQuery(
        _jobs
            .doc(jobId)
            .collection('quotations')
            .where('worker_uid', isEqualTo: workerUid)
            .limit(1),
      );
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
  // Always fetches from server — OTP must never be read from stale cache.

  Future<bool> verifyOtp({
    required String jobId,
    required String enteredOtp,
  }) async {
    try {
      final doc = await _jobs
          .doc(jobId)
          .get(const GetOptions(source: Source.server));
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