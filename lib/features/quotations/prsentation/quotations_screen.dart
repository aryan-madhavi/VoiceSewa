import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/core/constants/color_constants.dart';
import 'package:voicesewa_client/features/quotations/prsentation/widgets/quotation_widgets.dart';
import 'package:voicesewa_client/shared/models/quotation_model.dart';
import 'package:voicesewa_client/features/quotations/providers/quotation_provider.dart';

class QuotationsScreen extends ConsumerWidget {
  final String jobId;

  const QuotationsScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotationsAsync = ref.watch(jobQuotationsProvider(jobId));

    return Scaffold(
      backgroundColor: ColorConstants.scaffold,
      appBar: AppBar(
        title: const Text('Quotations'),
        backgroundColor: ColorConstants.appBar,
      ),
      body: quotationsAsync.when(
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
              return QuotationCard(jobId: jobId, quotation: quotation);
            },
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

  const QuotationCard({
    super.key,
    required this.jobId,
    required this.quotation,
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
            // Worker Header
            QuotationWorkerHeader(quotation: quotation),
            const SizedBox(height: 16),

            // Cost and Time Estimates
            QuotationEstimates(
              cost: quotation.estimatedCost,
              time: quotation.estimatedTime,
            ),
            const SizedBox(height: 12),

            // Description and Notes
            QuotationDescription(
              description: quotation.description,
              notes: quotation.notes,
            ),

            // Action Buttons
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
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Quotation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select scheduled date:'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  selectedDate = date;
                }
              },
              child: Text(
                '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
              ),
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
                await actions.acceptQuotation(jobId, quotation.id, selectedDate);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Quotation accepted!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Confirm'),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
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