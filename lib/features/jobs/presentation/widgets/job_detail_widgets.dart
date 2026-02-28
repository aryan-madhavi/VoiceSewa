import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:voicesewa_client/core/constants/color_constants.dart';
import 'package:voicesewa_client/core/extensions/context_extensions.dart';
import 'package:voicesewa_client/shared/models/job_model.dart';

/// Service information card showing icon, name, and status
class ServiceInfoCard extends StatelessWidget {
  final Job job;

  const ServiceInfoCard({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(job.serviceIcon, size: 48, color: job.serviceColor),
            const SizedBox(height: 8),
            Text(
              job.serviceName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            StatusBadge(label: job.statusLabel, color: job.statusColor),
            // ✅ Worker info shown when assigned
            if (job.hasWorker) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person, size: 18, color: Colors.black54),
                  const SizedBox(width: 6),
                  Text(
                    job.workerName!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  if (job.workerRating != null) ...[
                    const SizedBox(width: 10),
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 3),
                    Text(
                      job.workerRating!.toStringAsFixed(1),
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Reusable status badge widget
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// ✅ OTP Card — shown only when job is scheduled (not inProgress)
/// Client shares this 4-digit code with the worker to start the job.
class JobOtpCard extends StatelessWidget {
  final String otp;

  const JobOtpCard({super.key, required this.otp});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange.shade300, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Text(
                  'Job Start OTP',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // OTP digits display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: otp.split('').map((digit) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 52,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.shade400, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      digit,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Text(
              'Share this code with your worker to begin the job',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
            ),
            const SizedBox(height: 8),
            // Copy button
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: otp));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.loc.oTPCopiedToClipboard),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.copy, size: 16),
              label: Text(context.loc.copyOTP),
              style: TextButton.styleFrom(
                foregroundColor: Colors.orange.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ✅ In-Progress banner — shown when job status is inProgress
class JobInProgressBanner extends StatelessWidget {
  final Job job;

  const JobInProgressBanner({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.amber.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.amber.shade400, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.engineering,
                color: Colors.amber.shade800,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Job is In Progress',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.amber.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    job.workerName != null
                        ? '${job.workerName} is currently working on your request'
                        : 'Your worker is currently on the job',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.amber.shade800,
                    ),
                  ),
                  if (job.formattedStartedDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Started: ${job.formattedStartedDate}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ✅ Bill Card — shown when job is completed.
/// Displays bill items and total if bill exists, otherwise shows "No bill yet".
class JobBillCard extends StatelessWidget {
  final JobBill? bill;

  const JobBillCard({super.key, this.bill});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (bill == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_long, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Bill',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.hourglass_empty,
                      size: 40,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No bill yet',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'The worker hasn\'t submitted a bill yet',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.receipt_long, color: ColorConstants.seed),
                    const SizedBox(width: 8),
                    Text(
                      'Bill',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  bill!.createdAt.day.toString().padLeft(2, '0') +
                      '/' +
                      bill!.createdAt.month.toString().padLeft(2, '0') +
                      '/' +
                      bill!.createdAt.year.toString(),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Bill items
            if (bill!.items.isNotEmpty) ...[
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            flex: 3,
                            child: Text(
                              'Item',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                          const Expanded(
                            child: Text(
                              'Qty',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              context.loc.price,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                          const Expanded(
                            child: Text(
                              'Total',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    ...bill!.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                item.name,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                item.quantity.toString(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '₹${item.unitPrice.toStringAsFixed(0)}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '₹${item.total.toStringAsFixed(0)}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            // Notes
            if (bill!.notes.isNotEmpty) ...[
              Text(
                'Notes: ${bill!.notes}',
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 12),
            ],
            // Total
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    '₹${bill!.totalAmount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Job description card
class JobDescriptionCard extends StatelessWidget {
  final String description;

  const JobDescriptionCard({super.key, required this.description});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Description',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(description),
          ],
        ),
      ),
    );
  }
}

/// Job address card
class JobAddressCard extends StatelessWidget {
  final String fullAddress;

  const JobAddressCard({super.key, required this.fullAddress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Address',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(fullAddress)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Job dates information card
class JobDatesCard extends StatelessWidget {
  final String createdDate;
  final String? scheduledDate;

  const JobDatesCard({
    super.key,
    required this.createdDate,
    this.scheduledDate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            InfoRow(label: context.loc.created, value: createdDate),
            if (scheduledDate != null) ...[
              const Divider(),
              InfoRow(label: context.loc.scheduled, value: scheduledDate!),
            ],
          ],
        ),
      ),
    );
  }
}

/// Reusable info row widget
class InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const InfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
}

/// ✅ Feedback Card — shown when job is completed.
/// Displays submitted feedback if it exists, otherwise shows a button
/// that opens a bottom-sheet popup to collect rating + comment.
class JobFeedbackCard extends StatelessWidget {
  final JobFeedback? existingFeedback;
  final Future<void> Function(double rating, String comment) onSubmit;

  const JobFeedbackCard({
    super.key,
    required this.existingFeedback,
    required this.onSubmit,
  });

  void _openFeedbackSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FeedbackBottomSheet(onSubmit: onSubmit),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Already submitted — show the existing rating and comment
    if (existingFeedback != null) {
      final fb = existingFeedback!;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    'Your Feedback',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < fb.rating.round() ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 28,
                  );
                }),
              ),
              if (fb.comment.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  fb.comment,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Not yet submitted — show button to open popup
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.rate_review_outlined, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Rate this Job',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'How was your experience?',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _openFeedbackSheet(context),
              icon: const Icon(Icons.add_reaction_outlined),
              label: Text(context.loc.addFeedback),
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorConstants.seed,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet popup for collecting feedback
class _FeedbackBottomSheet extends StatefulWidget {
  final Future<void> Function(double rating, String comment) onSubmit;

  const _FeedbackBottomSheet({required this.onSubmit});

  @override
  State<_FeedbackBottomSheet> createState() => _FeedbackBottomSheetState();
}

class _FeedbackBottomSheetState extends State<_FeedbackBottomSheet> {
  double _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String get _ratingLabel {
    switch (_rating.toInt()) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent!';
      default:
        return 'Tap a star to rate';
    }
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.loc.pleaseSelectAStarRating)),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit(_rating, _commentController.text.trim());
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Respect keyboard insets so the sheet scrolls up when keyboard opens
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          const Text(
            'Rate Your Experience',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Your feedback helps us improve',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 28),

          // Star row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              return GestureDetector(
                onTap: () => setState(() => _rating = (i + 1).toDouble()),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    i < _rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: i < _rating ? Colors.amber : Colors.grey.shade300,
                    size: 52,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),

          // Rating label
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              _ratingLabel,
              key: ValueKey(_rating),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _rating > 0 ? Colors.amber.shade700 : Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Comment field
          TextField(
            controller: _commentController,
            maxLines: 3,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: context.loc.writeACommentOptional,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: ColorConstants.seed,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(context.loc.maybeLater),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: ColorConstants.seed,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Job action buttons (cancel, reschedule, view quotations)
class JobActionButtons extends StatelessWidget {
  final Job job;
  final int? unviewedQuotationsCount;
  final VoidCallback? onViewQuotations;
  final VoidCallback? onCancel;
  final VoidCallback? onReschedule;

  const JobActionButtons({
    super.key,
    required this.job,
    this.unviewedQuotationsCount,
    this.onViewQuotations,
    this.onCancel,
    this.onReschedule,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // View Quotations button
        if (job.isQuoted ||
            job.isScheduled ||
            job.isInProgress ||
            job.isCompleted)
          FilledButton.icon(
            onPressed: onViewQuotations,
            icon: const Icon(Icons.receipt_long),
            label: Text(
              unviewedQuotationsCount != null && unviewedQuotationsCount! > 0
                  ? 'View Quotations ($unviewedQuotationsCount new)'
                  : 'View Quotations',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: ColorConstants.seed,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),

        // Cancel button
        if (job.canBeCancelled) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.cancel),
            label: Text(context.loc.cancelJob),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],

        // Reschedule button
        if (job.canBeRescheduled) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onReschedule,
            icon: const Icon(Icons.schedule),
            label: Text(context.loc.rescheduleJob),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ],
    );
  }
}
