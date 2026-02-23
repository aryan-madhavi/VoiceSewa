import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/core/constants/color_constants.dart';
import 'package:voicesewa_client/features/quotations/prsentation/widgets/quotation_widgets.dart';
import 'package:voicesewa_client/features/jobs/providers/job_provider.dart';
import 'package:voicesewa_client/shared/models/job_model.dart';
import 'package:voicesewa_client/shared/models/quotation_model.dart';
import 'package:voicesewa_client/features/quotations/providers/quotation_provider.dart';

class QuotationsScreen extends ConsumerWidget {
  final String jobId;

  const QuotationsScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotationsAsync = ref.watch(jobQuotationsProvider(jobId));
    final jobAsync = ref.watch(jobProvider(jobId));

    return Scaffold(
      backgroundColor: ColorConstants.scaffold,
      appBar: AppBar(
        title: const Text('Quotations'),
        backgroundColor: ColorConstants.appBar,
      ),
      body: jobAsync.when(
        data: (job) {
          if (job == null) {
            return const Center(child: Text('Job not found'));
          }
          return quotationsAsync.when(
            data: (quotations) {
              if (quotations.isEmpty) {
                return const NoQuotationsPlaceholder();
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: quotations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final quotation = quotations[index];
                  return QuotationCard(
                    jobId: jobId,
                    quotation: quotation,
                    job: job,
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

/// Complete quotation card widget
class QuotationCard extends ConsumerWidget {
  final String jobId;
  final Quotation quotation;
  final Job job;

  const QuotationCard({
    super.key,
    required this.jobId,
    required this.quotation,
    required this.job,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mark as viewed when shown
    if (!quotation.viewedByClient && quotation.isPending) {
      Future.microtask(() {
        ref.read(quotationActionsProvider).markAsViewed(jobId, quotation.id);
      });
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Worker Header (name, rating, status badge, unread dot, submitted date)
            QuotationWorkerHeader(quotation: quotation),
            const SizedBox(height: 16),

            // Cost, Time, and Availability
            QuotationEstimates(
              cost: quotation.estimatedCost,
              time: quotation.estimatedTime,
              availability: quotation.availability,
            ),
            const SizedBox(height: 12),

            // Description, Notes, Price Breakdown, Timestamps, Reason banners
            QuotationDescription(quotation: quotation),

            // Action Buttons (only for pending/submitted quotations)
            if (quotation.canBeAccepted) ...[
              const SizedBox(height: 16),
              QuotationActionButtons(
                onAccept: () => _showAcceptDialog(context, ref),
                onReject: () => _showRejectDialog(context, ref),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAcceptDialog(BuildContext context, WidgetRef ref) {
    final scheduledAt = job.scheduledAt;

    if (scheduledAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No scheduled date found for this job. Please update the job first.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final formattedDate =
        '${scheduledAt.day}/${scheduledAt.month}/${scheduledAt.year}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Quotation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Worker info summary
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: ColorConstants.seed,
                  radius: 18,
                  child: Text(
                    (quotation.workerName.trim().isNotEmpty
                            ? quotation.workerName.trim()[0]
                            : 'W')
                        .toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quotation.workerName.trim().isNotEmpty
                          ? quotation.workerName.trim()
                          : 'Worker',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      quotation.estimatedCost,
                      style: const TextStyle(color: Colors.green),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Show job's existing scheduled date
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scheduled Date',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Accepting will assign this worker to your job and generate a start OTP.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final actions = ref.read(quotationActionsProvider);
                await actions.acceptQuotation(jobId, quotation.id, scheduledAt);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Quotation accepted! OTP generated.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirm Accept'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, WidgetRef ref) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Quotation'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason (optional)',
            hintText: 'Why are you rejecting this?',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final reason = reasonController.text.trim().isEmpty
                  ? 'Not selected'
                  : reasonController.text.trim();
              Navigator.pop(context);
              try {
                final actions = ref.read(quotationActionsProvider);
                await actions.rejectQuotation(jobId, quotation.id, reason);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Quotation rejected')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}
