import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voicesewa_client/shared/models/quotation_model.dart';

/// Firebase service for quotation operations
/// Handles all quotation CRUD operations as subcollection of jobs
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
  CollectionReference<Map<String, dynamic>> _quotationsCollection(String jobId) {
    return _firestore
        .collection(_jobsCollection)
        .doc(jobId)
        .collection(_quotationsSubcollection);
  }

  /// Create/Submit a quotation
  /// Works offline - will sync when online
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
      final jobDoc = await _firestore.collection(_jobsCollection).doc(jobId).get();

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
  Future<Quotation?> getQuotation(String jobId, String quotationId) async {
    try {
      print('📖 Fetching quotation: $quotationId');

      // Try cache first
      final cacheSnapshot = await _quotationsCollection(jobId)
          .doc(quotationId)
          .get(const GetOptions(source: Source.cache));

      if (cacheSnapshot.exists) {
        print('✅ Quotation found in cache');
        final quotation = Quotation.fromMap(quotationId, cacheSnapshot.data()!);

        // Fetch from server in background
        _quotationsCollection(jobId).doc(quotationId).get().then((serverSnapshot) {
          if (serverSnapshot.exists) {
            print('🔄 Quotation updated from server');
          }
        }).catchError((e) {
          print('⚠️ Server fetch failed (offline): $e');
        });

        return quotation;
      }

      // Not in cache, try server
      final serverSnapshot = await _quotationsCollection(jobId).doc(quotationId).get();

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
  Stream<Quotation?> watchQuotation(String jobId, String quotationId) {
    return _quotationsCollection(jobId).doc(quotationId).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return Quotation.fromMap(quotationId, snapshot.data()!);
      }
      return null;
    });
  }

  /// Get all quotations for a job
  Future<List<Quotation>> getJobQuotations(String jobId) async {
    try {
      print('📖 Fetching quotations for job: $jobId');

      final snapshot = await _quotationsCollection(jobId)
          .orderBy('created_at', descending: true)
          .get();

      final quotations = snapshot.docs
          .map((doc) => Quotation.fromMap(doc.id, doc.data()))
          .toList();

      print('✅ Found ${quotations.length} quotations');
      return quotations;
    } catch (e) {
      print('❌ Error fetching quotations: $e');
      rethrow;
    }
  }

  /// Stream all quotations for a job in real-time
  Stream<List<Quotation>> watchJobQuotations(String jobId) {
    return _quotationsCollection(jobId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Quotation.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  /// Get quotations by status
  Future<List<Quotation>> getQuotationsByStatus(
    String jobId,
    QuotationStatus status,
  ) async {
    try {
      print('📖 Fetching ${status.value} quotations for job: $jobId');

      final snapshot = await _quotationsCollection(jobId)
          .where('status', isEqualTo: status.value)
          .orderBy('created_at', descending: true)
          .get();

      final quotations = snapshot.docs
          .map((doc) => Quotation.fromMap(doc.id, doc.data()))
          .toList();

      print('✅ Found ${quotations.length} ${status.value} quotations');
      return quotations;
    } catch (e) {
      print('❌ Error fetching quotations by status: $e');
      rethrow;
    }
  }

  /// Accept a quotation
  Future<void> acceptQuotation(String jobId, String quotationId) async {
    try {
      print('📝 Accepting quotation: $quotationId');

      await _quotationsCollection(jobId).doc(quotationId).update({
        'status': QuotationStatus.accepted.value,
        'accepted_at': Timestamp.fromDate(DateTime.now()),
        'updated_at': Timestamp.fromDate(DateTime.now()),
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
  Future<void> _autoRejectOtherQuotations(
    String jobId,
    String acceptedQuotationId,
  ) async {
    try {
      final snapshot = await _quotationsCollection(jobId)
          .where('status', isEqualTo: QuotationStatus.submitted.value)
          .get();

      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        if (doc.id != acceptedQuotationId) {
          batch.update(doc.reference, {
            'status': QuotationStatus.rejected.value,
            'rejected_at': Timestamp.fromDate(DateTime.now()),
            'updated_at': Timestamp.fromDate(DateTime.now()),
            'auto_rejected': true,
          });
        }
      }

      await batch.commit();
      print('✅ Other quotations auto-rejected');
    } catch (e) {
      print('⚠️ Error auto-rejecting quotations: $e');
    }
  }

  /// Reject a quotation
  Future<void> rejectQuotation(
    String jobId,
    String quotationId,
    String reason,
  ) async {
    try {
      print('📝 Rejecting quotation: $quotationId');

      await _quotationsCollection(jobId).doc(quotationId).update({
        'status': QuotationStatus.rejected.value,
        'rejected_at': Timestamp.fromDate(DateTime.now()),
        'rejection_reason': reason,
        'updated_at': Timestamp.fromDate(DateTime.now()),
      });

      print('✅ Quotation rejected');
    } catch (e) {
      print('❌ Error rejecting quotation: $e');
      rethrow;
    }
  }

  /// Withdraw a quotation (by worker)
  Future<void> withdrawQuotation(
    String jobId,
    String quotationId,
    String reason,
  ) async {
    try {
      print('📝 Withdrawing quotation: $quotationId');

      await _quotationsCollection(jobId).doc(quotationId).update({
        'status': QuotationStatus.withdrawn.value,
        'withdrawn_at': Timestamp.fromDate(DateTime.now()),
        'withdrawal_reason': reason,
        'updated_at': Timestamp.fromDate(DateTime.now()),
      });

      print('✅ Quotation withdrawn');
    } catch (e) {
      print('❌ Error withdrawing quotation: $e');
      rethrow;
    }
  }

  /// Mark quotation as viewed by client
  Future<void> markAsViewed(String jobId, String quotationId) async {
    try {
      await _quotationsCollection(jobId).doc(quotationId).update({
        'viewed_by_client': true,
        'viewed_at': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('⚠️ Error marking quotation as viewed: $e');
    }
  }

  /// Get unviewed quotations count
  Future<int> getUnviewedQuotationsCount(String jobId) async {
    try {
      final snapshot = await _quotationsCollection(jobId)
          .where('viewed_by_client', isEqualTo: false)
          .where('status', isEqualTo: QuotationStatus.submitted.value)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('❌ Error getting unviewed count: $e');
      return 0;
    }
  }

  /// Stream unviewed quotations count
  Stream<int> watchUnviewedQuotationsCount(String jobId) {
    return _quotationsCollection(jobId)
        .where('viewed_by_client', isEqualTo: false)
        .where('status', isEqualTo: QuotationStatus.submitted.value)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}