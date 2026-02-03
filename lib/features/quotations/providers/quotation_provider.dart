import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/features/quotations/firebase/quotation_firebase_service.dart';
import 'package:voicesewa_client/shared/models/quotation_model.dart';
import 'package:voicesewa_client/features/jobs/providers/job_provider.dart';
import 'package:voicesewa_client/features/quotations/repository/quotation_repository.dart';

// ==================== SERVICE & REPOSITORY PROVIDERS ====================

/// Provider for Quotation Firebase service
final quotationFirebaseServiceProvider =
    Provider<QuotationFirebaseService>((ref) {
  return QuotationFirebaseService();
});

/// Provider for Quotation repository
final quotationRepositoryProvider = Provider<QuotationRepository>((ref) {
  final quotationService = ref.watch(quotationFirebaseServiceProvider);
  final jobService = ref.watch(jobFirebaseServiceProvider);
  return QuotationRepository(quotationService, jobService);
});

// ==================== DATA PROVIDERS ====================

/// Provider to get all quotations for a job with real-time updates
final jobQuotationsProvider = StreamProvider.autoDispose
    .family<List<Quotation>, String>((ref, jobId) {
  final repository = ref.watch(quotationRepositoryProvider);
  return repository.watchJobQuotations(jobId);
});

/// Provider to get a specific quotation with real-time updates
final quotationProvider = StreamProvider.autoDispose
    .family<Quotation?, ({String jobId, String quotationId})>((ref, params) {
  final repository = ref.watch(quotationRepositoryProvider);
  return repository.watchQuotation(params.jobId, params.quotationId);
});

/// Provider to get unviewed quotations count for a job
final unviewedQuotationsCountProvider =
    StreamProvider.autoDispose.family<int, String>((ref, jobId) {
  final repository = ref.watch(quotationRepositoryProvider);
  return repository.watchUnviewedCount(jobId);
});

/// Provider to get submitted quotations only
final submittedQuotationsProvider =
    FutureProvider.autoDispose.family<List<Quotation>, String>((ref, jobId) async {
  final repository = ref.watch(quotationRepositoryProvider);
  final allQuotations = await ref.watch(jobQuotationsProvider(jobId).future);
  return allQuotations
      .where((q) => q.status == QuotationStatus.submitted)
      .toList();
});

// ==================== ACTIONS PROVIDER ====================

/// Provider for quotation actions (accept, reject, mark as viewed)
final quotationActionsProvider = Provider<QuotationActions>((ref) {
  final repository = ref.watch(quotationRepositoryProvider);
  return QuotationActions(repository, ref);
});

/// Quotation actions class
class QuotationActions {
  final QuotationRepository _repository;
  final Ref _ref;

  QuotationActions(this._repository, this._ref);

  /// Accept a quotation
  Future<void> acceptQuotation(
    String jobId,
    String quotationId,
    DateTime scheduledAt,
  ) async {
    await _repository.acceptQuotation(jobId, quotationId, scheduledAt);

    // Invalidate caches to refresh UI
    _ref.invalidate(jobQuotationsProvider(jobId));
    _ref.invalidate(quotationProvider((jobId: jobId, quotationId: quotationId)));
    _ref.invalidate(jobProvider(jobId));
    _ref.invalidate(currentUserJobsProvider);
  }

  /// Reject a quotation
  Future<void> rejectQuotation(
    String jobId,
    String quotationId,
    String reason,
  ) async {
    await _repository.rejectQuotation(jobId, quotationId, reason);

    // Invalidate caches
    _ref.invalidate(jobQuotationsProvider(jobId));
    _ref.invalidate(quotationProvider((jobId: jobId, quotationId: quotationId)));
  }

  /// Mark quotation as viewed
  Future<void> markAsViewed(String jobId, String quotationId) async {
    await _repository.markAsViewed(jobId, quotationId);

    // Invalidate caches
    _ref.invalidate(unviewedQuotationsCountProvider(jobId));
    _ref.invalidate(quotationProvider((jobId: jobId, quotationId: quotationId)));
  }
}