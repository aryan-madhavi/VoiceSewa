import 'package:voicesewa_client/features/jobs/firebase/job_firebase_service.dart';
import 'package:voicesewa_client/features/jobs/firebase/quotation_firebase_service.dart';
import 'package:voicesewa_client/shared/models/quotation_model.dart';

/// Repository for quotation operations with business logic
class QuotationRepository {
  final QuotationFirebaseService _quotationService;
  final JobFirebaseService _jobService;

  QuotationRepository(this._quotationService, this._jobService);

  /// Get all quotations for a job
  Future<List<Quotation>> getJobQuotations(String jobId) async {
    return await _quotationService.getJobQuotations(jobId);
  }

  /// Stream quotations for a job
  Stream<List<Quotation>> watchJobQuotations(String jobId) {
    return _quotationService.watchJobQuotations(jobId);
  }

  /// Get quotation by ID
  Future<Quotation?> getQuotation(String jobId, String quotationId) async {
    return await _quotationService.getQuotation(jobId, quotationId);
  }

  /// Stream quotation updates
  Stream<Quotation?> watchQuotation(String jobId, String quotationId) {
    return _quotationService.watchQuotation(jobId, quotationId);
  }

  /// Accept quotation with validation
  Future<void> acceptQuotation(
    String jobId,
    String quotationId,
    DateTime scheduledAt,
  ) async {
    final quotation = await _quotationService.getQuotation(jobId, quotationId);

    if (quotation == null) {
      throw Exception('Quotation not found');
    }

    if (!quotation.canBeAccepted) {
      throw Exception(
        'Quotation cannot be accepted (status: ${quotation.status.value})',
      );
    }

    if (scheduledAt.isBefore(DateTime.now())) {
      throw ArgumentError('Cannot schedule in the past');
    }

    // Accept the quotation
    await _quotationService.acceptQuotation(jobId, quotationId);

    // Update job with worker details
    await _jobService.finalizeQuotation(
      jobId,
      quotationId,
      quotation.workerUid,
      quotation.workerName,
      quotation.workerRating,
      quotation.estimatedCost,
      quotation.estimatedTime,
      scheduledAt,
    );
  }

  /// Reject quotation
  Future<void> rejectQuotation(
    String jobId,
    String quotationId,
    String reason,
  ) async {
    if (reason.trim().isEmpty) {
      throw ArgumentError('Rejection reason is required');
    }

    await _quotationService.rejectQuotation(jobId, quotationId, reason.trim());
  }

  /// Mark quotation as viewed
  Future<void> markAsViewed(String jobId, String quotationId) async {
    await _quotationService.markAsViewed(jobId, quotationId);
  }

  /// Get unviewed quotations count
  Future<int> getUnviewedCount(String jobId) async {
    return await _quotationService.getUnviewedQuotationsCount(jobId);
  }

  /// Stream unviewed count
  Stream<int> watchUnviewedCount(String jobId) {
    return _quotationService.watchUnviewedQuotationsCount(jobId);
  }

  /// Get submitted quotations only
  Future<List<Quotation>> getSubmittedQuotations(String jobId) async {
    return await _quotationService.getQuotationsByStatus(
      jobId,
      QuotationStatus.submitted,
    );
  }
}