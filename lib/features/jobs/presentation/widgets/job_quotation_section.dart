import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_worker/core/constants/color_constants.dart';
import 'package:voicesewa_worker/features/jobs/providers/job_provider.dart';
import 'package:voicesewa_worker/shared/models/quotation_model.dart';
import 'job_section_card.dart';
import 'quotation_form.dart';

class JobQuotationSection extends ConsumerStatefulWidget {
  final String jobId;

  const JobQuotationSection({super.key, required this.jobId});

  @override
  ConsumerState<JobQuotationSection> createState() =>
      _JobQuotationSectionState();
}

class _JobQuotationSectionState extends ConsumerState<JobQuotationSection> {
  bool _showForm = false;
  bool _isEditMode = false;

  @override
  Widget build(BuildContext context) {
    final _workerUid = ref.watch(currentWorkerUidProvider);
    final existingQuotation = ref.watch(
      myQuotationProvider((widget.jobId, _workerUid)),
    );

    return existingQuotation.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (_, __) => _buildSubmitTile(),
      data: (quotation) {
        if (quotation == null) return _buildSubmitTile();
        if (_showForm) return _buildFormTile(quotation);
        return _buildExistingCard(quotation);
      },
    );
  }

  // ── Existing quotation card ───────────────────────────────────────────────

  Widget _buildExistingCard(QuotationModel quotation) {
    final statusColor =
        {
          QuotationStatus.submitted: ColorConstants.warningOrange,
          QuotationStatus.accepted: ColorConstants.successGreen,
          QuotationStatus.rejected: ColorConstants.errorRed,
          QuotationStatus.withdrawn: ColorConstants.unselectedGrey,
        }[quotation.status] ??
        ColorConstants.warningOrange;

    // Edit: only if not yet viewed by client AND still submitted
    final canEdit =
        !quotation.viewedByClient &&
        quotation.status == QuotationStatus.submitted;

    // Withdraw: only before accepted (submitted or rejected — not accepted/withdrawn)
    final canWithdraw =
        quotation.status == QuotationStatus.submitted ||
        quotation.status == QuotationStatus.rejected;

    return JobSectionCard(
      title: 'Your Quotation',
      icon: Icons.request_quote_outlined,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cost + status badge row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${quotation.estimatedCost}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: ColorConstants.primaryBlue,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    quotation.status.value.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            JobDetailRow(
              Icons.timer_outlined,
              'Est. Time',
              quotation.estimatedTime,
            ),
            if (quotation.availability.isNotEmpty) ...[
              const SizedBox(height: 8),
              JobDetailRow(
                Icons.event_available_outlined,
                'Available',
                quotation.availability,
              ),
            ],
            if (quotation.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              JobDetailRow(
                Icons.notes_outlined,
                'Details',
                quotation.description,
              ),
            ],
            if (quotation.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              JobDetailRow(
                Icons.sticky_note_2_outlined,
                'Notes',
                quotation.notes,
              ),
            ],

            // Price breakdown
            if (quotation.priceBreakdown != null &&
                quotation.priceBreakdown!.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),
              const Text(
                'Price Breakdown',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.textGrey,
                ),
              ),
              const SizedBox(height: 6),
              ...quotation.priceBreakdown!.entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        e.key,
                        style: const TextStyle(
                          fontSize: 13,
                          color: ColorConstants.textDark,
                        ),
                      ),
                      Text(
                        '₹${e.value}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: ColorConstants.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Seen by client badge
            if (quotation.viewedByClient) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.visibility_outlined,
                    size: 13,
                    color: ColorConstants.seenGreen,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Seen by client',
                    style: TextStyle(
                      fontSize: 12,
                      color: ColorConstants.seenGreen,
                    ),
                  ),
                ],
              ),
            ],

            // Withdrawal reason (if withdrawn)
            if (quotation.status == QuotationStatus.withdrawn &&
                (quotation.withdrawalReason?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ColorConstants.chipGreySurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 14,
                      color: ColorConstants.textGrey,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Withdrawal reason: ${quotation.withdrawalReason}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: ColorConstants.textGrey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action buttons
            if (canEdit || canWithdraw) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  if (canEdit) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit'),
                        onPressed: () => setState(() {
                          _showForm = true;
                          _isEditMode = true;
                        }),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ColorConstants.primaryBlue,
                          side: BorderSide(
                            color: ColorConstants.primaryBlue.withOpacity(0.5),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  if (canWithdraw)
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.undo_outlined, size: 16),
                        label: const Text('Withdraw'),
                        onPressed: () => _showWithdrawDialog(quotation),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ColorConstants.errorRed,
                          side: BorderSide(
                            color: ColorConstants.errorRed.withOpacity(0.4),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Form tile (submit or edit) ────────────────────────────────────────────

  Widget _buildFormTile(QuotationModel existing) {
    return JobSectionCard(
      title: _isEditMode ? 'Edit Quotation' : 'Submit Quotation',
      icon: Icons.request_quote_outlined,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: QuotationForm(
          jobId: widget.jobId,
          existingQuotation: _isEditMode ? existing : null,
          onCancel: () => setState(() {
            _showForm = false;
            _isEditMode = false;
          }),
          onSubmitted: () {
            setState(() {
              _showForm = false;
              _isEditMode = false;
            });
            ref.invalidate(
              myQuotationProvider((
                widget.jobId,
                ref.read(currentWorkerUidProvider),
              )),
            );
          },
        ),
      ),
    );
  }

  // ── Submit tile (no quotation yet) ────────────────────────────────────────

  Widget _buildSubmitTile() {
    return JobSectionCard(
      title: 'Submit Quotation',
      icon: Icons.request_quote_outlined,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _showForm
            ? QuotationForm(
                jobId: widget.jobId,
                onCancel: () => setState(() => _showForm = false),
                onSubmitted: () {
                  setState(() => _showForm = false);
                  ref.invalidate(
                    myQuotationProvider((
                      widget.jobId,
                      ref.read(currentWorkerUidProvider),
                    )),
                  );
                },
              )
            : Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text(
                      'Submit your quotation to apply for this job. The client will review it and may accept your offer.',
                      style: TextStyle(
                        fontSize: 13,
                        color: ColorConstants.textGrey,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_circle_outline, size: 16),
                      onPressed: () => setState(() => _showForm = true),
                      label: const Text(
                        'Submit Quotation',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConstants.primaryBlue,
                        foregroundColor: ColorConstants.pureWhite,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
      ),
    );
  }

  // ── Withdraw dialog ───────────────────────────────────────────────────────

  Future<void> _showWithdrawDialog(QuotationModel quotation) async {
    final reasonController = TextEditingController();
    bool submitted = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.undo_outlined, color: ColorConstants.errorRed),
              SizedBox(width: 8),
              Text('Withdraw Quotation'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please provide a reason for withdrawal.',
                style: TextStyle(fontSize: 13, color: ColorConstants.textGrey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 3,
                autofocus: true,
                onChanged: (_) => setLocal(() {}),
                decoration: InputDecoration(
                  hintText: 'e.g. Not available on that date...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: ColorConstants.chipGreySurface2,
                  contentPadding: const EdgeInsets.all(10),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: reasonController.text.trim().isEmpty
                  ? null
                  : () {
                      submitted = true;
                      Navigator.of(ctx).pop();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.errorRed,
                foregroundColor: ColorConstants.pureWhite,
                disabledBackgroundColor: ColorConstants.errorRed.withOpacity(
                  0.3,
                ),
              ),
              child: const Text('Confirm Withdrawal'),
            ),
          ],
        ),
      ),
    );

    if (submitted && mounted) {
      final success = await ref.read(withdrawQuotationProvider)(
        jobId: widget.jobId,
        quotationId: quotation.quotationId,
        reason: reasonController.text.trim(),
      );
      reasonController.dispose();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? '✅ Quotation withdrawn' : '❌ Failed. Please try again.',
            ),
            backgroundColor: success
                ? ColorConstants.warningOrange
                : ColorConstants.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
        if (success)
          ref.invalidate(
            myQuotationProvider((
              widget.jobId,
              ref.read(currentWorkerUidProvider),
            )),
          );
      }
    } else {
      reasonController.dispose();
    }
  }
}
