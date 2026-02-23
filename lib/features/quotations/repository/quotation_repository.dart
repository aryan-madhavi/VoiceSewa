import 'package:voicesewa_client/features/jobs/firebase/job_firebase_service.dart';
import 'package:voicesewa_client/features/quotations/firebase/quotation_firebase_service.dart';
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

  /// Accept quotation with validation.
  ///
  /// The [scheduledAt] date is fetched from the job's own [scheduled_at] field
  /// (set by the client during job creation). Date comparison uses date-only
  /// (no time component) so that today's date is always valid.
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

    // ✅ Compare date-only (strip time) so today's date is always allowed.
    // The scheduledAt comes from the job document (set during job creation),
    // not from the quotation accept dialog.
    final now = DateTime.now();
    final todayOnly = DateTime(now.year, now.month, now.day);
    final scheduledOnly = DateTime(
      scheduledAt.year,
      scheduledAt.month,
      scheduledAt.day,
    );

    if (scheduledOnly.isBefore(todayOnly)) {
      throw ArgumentError(
        'Scheduled date cannot be in the past. '
        'Please update the job scheduled date first.',
      );
    }

    // Accept the quotation
    await _quotationService.acceptQuotation(jobId, quotationId);

    // Update job with worker details + generate OTP
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
