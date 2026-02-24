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

  Future<DocumentSnapshot> _getDoc(DocumentReference ref) async {
    try {
      return await ref.get(const GetOptions(source: Source.server));
    } catch (_) {
      try {
        return await ref.get(const GetOptions(source: Source.cache));
      } catch (e) {
        rethrow;
      }
    }
  }

  // ── Smart query fetch ─────────────────────────────────────────────────────

  Future<QuerySnapshot> _getQuery(Query query) async {
    try {
      return await query.get(const GetOptions(source: Source.server));
    } catch (_) {
      return await query.get(const GetOptions(source: Source.cache));
    }
  }

  // ── Parallel document fetch ───────────────────────────────────────────────

  Future<List<JobModel>> _fetchJobRefs(List<DocumentReference> refs) async {
    if (refs.isEmpty) return [];
    final docs = await Future.wait(refs.map(_getDoc));
    return docs.where((d) => d.exists).map((d) => JobModel.fromDoc(d)).toList();
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

  // ── Map skills → Services enum ────────────────────────────────────────────

  Set<Services> _skillsToServices(List<String> skills) {
    final result = <Services>{};
    for (final skill in skills) {
      final entry = ServicesData.services.entries.firstWhere(
        (e) =>
            (e.value[2] as String).toLowerCase().trim() ==
            skill.toLowerCase().trim(),
        orElse: () => const MapEntry(Services.handymanMasonryWork, []),
      );
      if ((entry.value as List).isNotEmpty) result.add(entry.key);
    }
    return result;
  }

  // ── Real-time incoming jobs stream ────────────────────────────────────────
  // Two-level real-time listener — pure dart:async, no external packages.
  //
  // Level 1 — worker doc snapshots():
  //   Watches declined[], applied[], location, and skills live.
  //   Any change (new decline, new application, location update) cancels
  //   all Level-2 listeners and restarts them fresh.
  //
  // Level 2 — per-service jobs/ collection snapshots():
  //   One listener per (service × status) combination for
  //   status ∈ ['requested', 'quoted'].
  //   When any job doc changes, re-applies distance filter + display
  //   override and re-emits the full merged list.
  //
  // Display override (same logic as fetchIncomingJobs):
  //   If job.status == 'quoted' but THIS worker hasn't applied yet
  //   → show locally as 'requested' (open/new).
  //   If THIS worker HAS applied → keep 'quoted' so it shows correctly.

  Stream<List<JobModel>> watchIncomingJobs({
    required String workerUid,
    double radiusKm = 5.0,
    int limitPerService = 50,
  }) {
    final outerController = StreamController<List<JobModel>>();

    StreamSubscription? workerSub;
    final List<StreamSubscription> jobQuerySubs = [];

    void cancelJobSubs() {
      for (final s in jobQuerySubs) s.cancel();
      jobQuerySubs.clear();
    }

    workerSub = _workers
        .doc(workerUid)
        .snapshots()
        .listen(
          (workerSnap) {
            // Worker doc changed — cancel old job query listeners and restart
            cancelJobSubs();

            if (!workerSnap.exists) {
              if (!outerController.isClosed) outerController.add([]);
              return;
            }

            final workerData = workerSnap.data() as Map<String, dynamic>? ?? {};
            final jobsMap = workerData['jobs'] as Map<String, dynamic>? ?? {};

            // Worker location — required for distance filtering
            final addressMap = workerData['address'] as Map<String, dynamic>?;
            final rawLoc = addressMap?['location'];
            final GeoPoint? workerLocation = rawLoc is GeoPoint ? rawLoc : null;

            // Worker skills — required to build service queries
            final skills = List<String>.from(workerData['skills'] ?? []);

            if (workerLocation == null || skills.isEmpty) {
              if (!outerController.isClosed) outerController.add([]);
              return;
            }

            final declinedIds = List<DocumentReference>.from(
              jobsMap['declined'] ?? [],
            ).map((r) => r.id).toSet();

            final appliedRefs = List<DocumentReference>.from(
              jobsMap['applied'] ?? [],
            );
            final appliedIds = appliedRefs.map((r) => r.id).toSet();

            final matchingServices = _skillsToServices(skills);
            if (matchingServices.isEmpty) {
              if (!outerController.isClosed) outerController.add([]);
              return;
            }

            // Build one query per (service × status) combination
            const openStatuses = ['requested', 'quoted'];
            final queries = [
              for (final service in matchingServices)
                for (final status in openStatuses)
                  _jobs
                      .where('service_type', isEqualTo: service.name)
                      .where('status', isEqualTo: status)
                      .limit(limitPerService),
            ];

            if (queries.isEmpty) {
              if (!outerController.isClosed) outerController.add([]);
              return;
            }

            // latest[i] holds the most recent snapshot for each query
            final latestSnaps = List<QuerySnapshot?>.filled(
              queries.length,
              null,
            );
            final received = List<bool>.filled(queries.length, false);
            int receivedCount = 0;

            // Called whenever any query snapshot arrives/updates.
            // Re-merges all latest snapshots and emits the filtered result.
            void recompute() {
              if (receivedCount < queries.length) return;

              final seen = <String>{};
              final results = <JobModel>[];

              for (final snap in latestSnaps) {
                if (snap == null) continue;
                for (final doc in snap.docs) {
                  if (seen.contains(doc.id)) continue;
                  if (declinedIds.contains(doc.id)) continue;

                  JobModel job = JobModel.fromDoc(doc);
                  final loc = job.address.location;
                  if (loc == null) continue;
                  if (_distanceKm(workerLocation, loc) > radiusKm) continue;

                  // Display override — same logic as fetchIncomingJobs
                  if (job.status == JobStatusType.quoted &&
                      !appliedIds.contains(job.jobId)) {
                    job = job.copyWith(status: JobStatusType.requested);
                  }

                  seen.add(job.jobId);
                  results.add(job);
                }
              }

              // Also include applied jobs that are still open (quoted/requested)
              // so they stay visible under the "Quoted" chip after applying.
              // We derive these from the already-loaded results — no extra fetch.
              // (Applied job docs are already captured by the 'quoted' query above.)

              results.sort((a, b) {
                final aDate = a.createdAt ?? DateTime(0);
                final bDate = b.createdAt ?? DateTime(0);
                return bDate.compareTo(aDate);
              });

              if (!outerController.isClosed) outerController.add(results);
            }

            for (int i = 0; i < queries.length; i++) {
              final index = i;
              final sub = queries[index].snapshots().listen(
                (snap) {
                  latestSnaps[index] = snap;
                  if (!received[index]) {
                    received[index] = true;
                    receivedCount++;
                  }
                  recompute();
                },
                onError: (e) {
                  if (!outerController.isClosed) outerController.addError(e);
                },
              );
              jobQuerySubs.add(sub);
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

  // ── Incoming jobs (one-shot fetch — kept for reference/fallback) ──────────

  Future<List<JobModel>> fetchIncomingJobs({
    required List<String> workerSkills,
    required GeoPoint workerLocation,
    required String workerUid,
    double radiusKm = 5.0,
    int limitPerService = 50,
  }) async {
    try {
      final matchingServices = _skillsToServices(workerSkills);
      if (matchingServices.isEmpty) {
        print(
          '⚠️ fetchIncomingJobs — no matching services for skills: $workerSkills',
        );
        return [];
      }

      final workerDoc = await _getDoc(_workers.doc(workerUid));
      final workerData = workerDoc.data() as Map<String, dynamic>? ?? {};
      final jobsMap = workerData['jobs'] as Map<String, dynamic>? ?? {};

      final declinedIds = List<DocumentReference>.from(
        jobsMap['declined'] ?? [],
      ).map((r) => r.id).toSet();
      final appliedRefs = List<DocumentReference>.from(
        jobsMap['applied'] ?? [],
      );
      final appliedIds = appliedRefs.map((r) => r.id).toSet();

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

          if (job.status == JobStatusType.quoted &&
              !appliedIds.contains(job.jobId)) {
            job = job.copyWith(status: JobStatusType.requested);
          }

          seen.add(job.jobId);
          results.add(job);
        }
      }

      if (appliedRefs.isNotEmpty) {
        final appliedDocs = await Future.wait(appliedRefs.map(_getDoc));
        for (final doc in appliedDocs) {
          if (!doc.exists) continue;
          final job = JobModel.fromDoc(doc);
          if (!seen.contains(job.jobId) &&
              (job.status == JobStatusType.quoted ||
                  job.status == JobStatusType.requested)) {
            seen.add(job.jobId);
            results.add(job);
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

  Stream<List<JobModel>> watchOngoingJobs(String workerUid) {
    const ongoingStatuses = {'scheduled', 'inProgress', 'rescheduled'};
    return _watchWorkerJobRefs(
      workerUid: workerUid,
      refsKey: 'confirmed',
      filter: (jobs) =>
          jobs.where((j) => ongoingStatuses.contains(j.status.value)).toList()
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
      filter: (jobs) =>
          jobs.where((j) => j.status == JobStatusType.completed).toList()
            ..sort((a, b) {
              final aDate = a.createdAt ?? DateTime(0);
              final bDate = b.createdAt ?? DateTime(0);
              return bDate.compareTo(aDate);
            }),
    );
  }

  // ── Load more completed jobs ──────────────────────────────────────────────

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

  // ── Master real-time ref-list watcher ─────────────────────────────────────

  Stream<List<JobModel>> _watchWorkerJobRefs({
    required String workerUid,
    required String refsKey,
    required List<JobModel> Function(List<JobModel>) filter,
    int? pageSize,
  }) {
    final outerController = StreamController<List<JobModel>>();
    StreamSubscription? workerSub;
    final List<StreamSubscription> jobSubs = [];

    void cancelJobSubs() {
      for (final s in jobSubs) s.cancel();
      jobSubs.clear();
    }

    workerSub = _workers
        .doc(workerUid)
        .snapshots()
        .listen(
          (workerSnap) {
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

            if (pageSize != null && refs.length > pageSize) {
              refs = refs.sublist(refs.length - pageSize);
            }

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
      final jobsMap = data['jobs'] as Map<String, dynamic>? ?? {};

      final declinedRefs = List<DocumentReference>.from(
        jobsMap['declined'] ?? [],
      );
      final appliedRefs = List<DocumentReference>.from(
        jobsMap['applied'] ?? [],
      );

      final results = await _fetchJobRefs(declinedRefs);

      if (appliedRefs.isNotEmpty) {
        final appliedJobs = await _fetchJobRefs(appliedRefs);
        for (final job in appliedJobs) {
          if (job.isCancelled) {
            results.add(job);
          }
        }
      }

      return results;
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
      final jobRef = _jobs.doc(jobId);
      final quoRef = jobRef.collection('quotations').doc();

      final jobSnap = await jobRef.get(const GetOptions(source: Source.server));
      final currentStatus = jobSnap.exists
          ? (jobSnap.data() as Map<String, dynamic>)['status'] as String? ?? ''
          : '';

      final batch = _firestore.batch();
      batch.set(quoRef, quotation.toMap());

      if (currentStatus == 'requested') {
        batch.update(jobRef, {'status': 'quoted'});
      }

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

  Stream<QuerySnapshot> watchMessages({
    required String jobId,
    required String quotationId,
  }) {
    return _jobs
        .doc(jobId)
        .collection('quotations')
        .doc(quotationId)
        .collection('messages')
        .orderBy('sent_at', descending: false)
        .snapshots();
  }

  Future<bool> sendMessage({
    required String jobId,
    required String quotationId,
    required String senderUid,
    required String senderName,
    required String text,
    required bool isWorker,
  }) async {
    try {
      await _jobs
          .doc(jobId)
          .collection('quotations')
          .doc(quotationId)
          .collection('messages')
          .add({
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
