import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voicesewa_client/shared/models/quotation_model.dart';

/// Firebase service for quotation operations
/// ✅ FULLY OFFLINE COMPATIBLE - All queries work offline
class QuotationFirebaseService {
  final FirebaseFirestore _firestore;
  static const String _jobsCollection = 'jobs';
  static const String _quotationsSubcollection = 'quotations';

  QuotationFirebaseService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance {
    // Enable offline persistence
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  /// Get quotations subcollection reference for a job
  CollectionReference<Map<String, dynamic>> _quotationsCollection(
    String jobId,
  ) {
    return _firestore
        .collection(_jobsCollection)
        .doc(jobId)
        .collection(_quotationsSubcollection);
  }

  /// Create/Submit a quotation
  /// ✅ WORKS OFFLINE - uses DateTime.now() instead of serverTimestamp
  Future<String> createQuotation(String jobId, Quotation quotation) async {
    try {
      print('💾 Creating quotation for job: $jobId');

      final docRef = await _quotationsCollection(jobId).add(quotation.toMap());

      // Update job status to 'quoted' if it's still 'requested'
      await _updateJobStatusIfRequested(jobId);

      print('✅ Quotation created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error creating quotation: $e');
      rethrow;
    }
  }

  /// Helper to update job status to 'quoted' when first quotation is received
  Future<void> _updateJobStatusIfRequested(String jobId) async {
    try {
      final jobDoc = await _firestore
          .collection(_jobsCollection)
          .doc(jobId)
          .get();

      if (jobDoc.exists && jobDoc.data()?['status'] == 'requested') {
        await _firestore.collection(_jobsCollection).doc(jobId).update({
          'status': 'quoted',
        });
      }
    } catch (e) {
      print('⚠️ Could not update job status: $e');
    }
  }

  /// Get quotation by ID
  /// ✅ WORKS OFFLINE - Cache-first strategy
  Future<Quotation?> getQuotation(String jobId, String quotationId) async {
    try {
      print('📖 Fetching quotation: $quotationId');

      // Try cache first
      final cacheSnapshot = await _quotationsCollection(
        jobId,
      ).doc(quotationId).get(const GetOptions(source: Source.cache));

      if (cacheSnapshot.exists) {
        print('✅ Quotation found in cache');
        final quotation = Quotation.fromMap(quotationId, cacheSnapshot.data()!);

        // Fetch from server in background
        _quotationsCollection(jobId)
            .doc(quotationId)
            .get()
            .then((serverSnapshot) {
              if (serverSnapshot.exists) {
                print('🔄 Quotation updated from server');
              }
            })
            .catchError((e) {
              print('⚠️ Server fetch failed (offline): $e');
            });

        return quotation;
      }

      // Not in cache, try server
      final serverSnapshot = await _quotationsCollection(
        jobId,
      ).doc(quotationId).get();

      if (serverSnapshot.exists) {
        print('✅ Quotation fetched from server');
        return Quotation.fromMap(quotationId, serverSnapshot.data()!);
      }

      print('ℹ️ Quotation not found: $quotationId');
      return null;
    } catch (e) {
      print('❌ Error fetching quotation: $e');
      rethrow;
    }
  }

  /// Stream quotation updates in real-time
  /// ✅ WORKS OFFLINE - Firestore handles offline snapshots
  Stream<Quotation?> watchQuotation(String jobId, String quotationId) {
    return _quotationsCollection(jobId).doc(quotationId).snapshots().map((
      snapshot,
    ) {
      if (snapshot.exists) {
        return Quotation.fromMap(quotationId, snapshot.data()!);
      }
      return null;
    });
  }

  /// Get all quotations for a job
  /// ✅ FIXED FOR OFFLINE - No orderBy, sort in memory
  Future<List<Quotation>> getJobQuotations(String jobId) async {
    try {
      print('📖 Fetching quotations for job: $jobId');

      // ✅ Try cache first for offline support
      QuerySnapshot<Map<String, dynamic>>? snapshot;

      try {
        snapshot = await _quotationsCollection(
          jobId,
        ).get(const GetOptions(source: Source.cache));
        print('✅ Loaded ${snapshot.docs.length} quotations from cache');
      } catch (e) {
        print('⚠️ Cache failed, trying server: $e');
      }

      // If cache failed or empty, try server
      if (snapshot == null || snapshot.docs.isEmpty) {
        try {
          snapshot = await _quotationsCollection(jobId).get();
          print('✅ Loaded ${snapshot.docs.length} quotations from server');
        } catch (e) {
          print('❌ Both cache and server failed: $e');
          return [];
        }
      }

      // ✅ Sort in memory instead of using orderBy
      final quotations = snapshot.docs
          .map((doc) => Quotation.fromMap(doc.id, doc.data()))
          .toList();

      quotations.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print('✅ Found ${quotations.length} quotations (sorted in memory)');
      return quotations;
    } catch (e) {
      print('❌ Error fetching quotations: $e');
      return [];
    }
  }

  /// Stream all quotations for a job in real-time
  /// ✅ FIXED FOR OFFLINE - No orderBy, sort in stream map
  Stream<List<Quotation>> watchJobQuotations(String jobId) {
    return _quotationsCollection(jobId).snapshots().map((snapshot) {
      // ✅ Sort in memory instead of orderBy
      final quotations = snapshot.docs
          .map((doc) => Quotation.fromMap(doc.id, doc.data()))
          .toList();

      quotations.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return quotations;
    });
  }

  /// Get quotations by status
  /// ✅ FIXED FOR OFFLINE - Sort in memory
  Future<List<Quotation>> getQuotationsByStatus(
    String jobId,
    QuotationStatus status,
  ) async {
    try {
      print('📖 Fetching ${status.value} quotations for job: $jobId');

      // ✅ Try cache first
      QuerySnapshot<Map<String, dynamic>>? snapshot;

      try {
        snapshot = await _quotationsCollection(jobId)
            .where('status', isEqualTo: status.value)
            .get(const GetOptions(source: Source.cache));
        print('✅ Loaded from cache');
      } catch (e) {
        print('⚠️ Cache failed, trying server: $e');
      }

      // If cache failed, try server
      if (snapshot == null || snapshot.docs.isEmpty) {
        try {
          snapshot = await _quotationsCollection(
            jobId,
          ).where('status', isEqualTo: status.value).get();
        } catch (e) {
          print('❌ Both cache and server failed: $e');
          return [];
        }
      }

      // ✅ Sort in memory
      final quotations = snapshot.docs
          .map((doc) => Quotation.fromMap(doc.id, doc.data()))
          .toList();

      quotations.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print('✅ Found ${quotations.length} ${status.value} quotations');
      return quotations;
    } catch (e) {
      print('❌ Error fetching quotations by status: $e');
      return [];
    }
  }

  /// Accept a quotation
  /// ✅ WORKS OFFLINE - Uses DateTime.now() instead of serverTimestamp
  Future<void> acceptQuotation(String jobId, String quotationId) async {
    try {
      print('🔏 Accepting quotation: $quotationId');

      final now = DateTime.now();

      await _quotationsCollection(jobId).doc(quotationId).update({
        'status': QuotationStatus.accepted.value,
        'accepted_at': Timestamp.fromDate(now),
        'updated_at': Timestamp.fromDate(now),
      });

      // Auto-reject all other submitted quotations
      await _autoRejectOtherQuotations(jobId, quotationId);

      print('✅ Quotation accepted');
    } catch (e) {
      print('❌ Error accepting quotation: $e');
      rethrow;
    }
  }

  /// Auto-reject other submitted quotations when one is accepted
  /// ✅ FIXED FOR OFFLINE - Individual updates instead of batch
  Future<void> _autoRejectOtherQuotations(
    String jobId,
    String acceptedQuotationId,
  ) async {
    try {
      // ✅ Try cache first
      QuerySnapshot<Map<String, dynamic>>? snapshot;

      try {
        snapshot = await _quotationsCollection(jobId)
            .where('status', isEqualTo: QuotationStatus.submitted.value)
            .get(const GetOptions(source: Source.cache));
      } catch (e) {
        print('⚠️ Cache failed for auto-reject, trying server: $e');
        snapshot = await _quotationsCollection(
          jobId,
        ).where('status', isEqualTo: QuotationStatus.submitted.value).get();
      }

      final now = DateTime.now();

      // ✅ Use individual updates instead of batch (works better offline)
      for (final doc in snapshot.docs) {
        if (doc.id != acceptedQuotationId) {
          try {
            await doc.reference.update({
              'status': QuotationStatus.rejected.value,
              'rejected_at': Timestamp.fromDate(now),
              'updated_at': Timestamp.fromDate(now),
              'auto_rejected': true,
            });
          } catch (e) {
            print('⚠️ Failed to auto-reject ${doc.id}: $e');
          }
        }
      }

      print('✅ Other quotations auto-rejected');
    } catch (e) {
      print('⚠️ Error auto-rejecting quotations: $e');
      // Don't rethrow - this is a secondary operation
    }
  }

  /// Reject a quotation
  /// ✅ WORKS OFFLINE - Uses DateTime.now() instead of serverTimestamp
  Future<void> rejectQuotation(
    String jobId,
    String quotationId,
    String reason,
  ) async {
    try {
      print('🔏 Rejecting quotation: $quotationId');

      final now = DateTime.now();

      await _quotationsCollection(jobId).doc(quotationId).update({
        'status': QuotationStatus.rejected.value,
        'rejected_at': Timestamp.fromDate(now),
        'rejection_reason': reason,
        'updated_at': Timestamp.fromDate(now),
      });

      print('✅ Quotation rejected');
    } catch (e) {
      print('❌ Error rejecting quotation: $e');
      rethrow;
    }
  }

  /// Withdraw a quotation (by worker)
  /// ✅ WORKS OFFLINE - Uses DateTime.now() instead of serverTimestamp
  Future<void> withdrawQuotation(
    String jobId,
    String quotationId,
    String reason,
  ) async {
    try {
      print('🔏 Withdrawing quotation: $quotationId');

      final now = DateTime.now();

      await _quotationsCollection(jobId).doc(quotationId).update({
        'status': QuotationStatus.withdrawn.value,
        'withdrawn_at': Timestamp.fromDate(now),
        'withdrawal_reason': reason,
        'updated_at': Timestamp.fromDate(now),
      });

      print('✅ Quotation withdrawn');
    } catch (e) {
      print('❌ Error withdrawing quotation: $e');
      rethrow;
    }
  }

  /// Mark quotation as viewed by client
  /// ✅ WORKS OFFLINE - Uses DateTime.now() instead of serverTimestamp
  Future<void> markAsViewed(String jobId, String quotationId) async {
    try {
      final now = DateTime.now();

      await _quotationsCollection(jobId).doc(quotationId).update({
        'viewed_by_client': true,
        'viewed_at': Timestamp.fromDate(now),
      });
    } catch (e) {
      print('⚠️ Error marking quotation as viewed: $e');
      // Don't rethrow - this is a non-critical operation
    }
  }

  /// Get unviewed quotations count
  /// ✅ FIXED FOR OFFLINE - Filter in memory
  Future<int> getUnviewedQuotationsCount(String jobId) async {
    try {
      // ✅ Get all quotations and filter in memory
      final allQuotations = await getJobQuotations(jobId);

      final unviewedCount = allQuotations
          .where((q) => !q.viewedByClient && q.isPending)
          .length;

      return unviewedCount;
    } catch (e) {
      print('❌ Error getting unviewed count: $e');
      return 0;
    }
  }

  /// Stream unviewed quotations count
  Stream<int> watchUnviewedQuotationsCount(String jobId) {
    return watchJobQuotations(jobId).map((quotations) {
      return quotations.where((q) => !q.viewedByClient && q.isPending).length;
    });
  }
}
