import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/core/constants/color_constants.dart';
import 'package:voicesewa_client/features/jobs/presentation/quotations_screen.dart';
import 'package:voicesewa_client/features/jobs/providers/job_provider.dart';
import 'package:voicesewa_client/features/jobs/providers/quotation_provider.dart';
import 'package:voicesewa_client/shared/models/job_model.dart';


class JobDetailsScreen extends ConsumerWidget {
  final String jobId;

  const JobDetailsScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobAsync = ref.watch(jobProvider(jobId));

    return Scaffold(
      backgroundColor: ColorConstants.scaffold,
      appBar: AppBar(
        title: const Text('Job Details'),
        backgroundColor: ColorConstants.appBar,
      ),
      body: jobAsync.when(
        data: (job) {
          if (job == null) {
            return const Center(child: Text('Job not found'));
          }
          return _JobDetailsContent(job: job);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _JobDetailsContent extends ConsumerWidget {
  final Job job;

  const _JobDetailsContent({required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final unviewedCountAsync = ref.watch(
      unviewedQuotationsCountProvider(job.id),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Service Card
          Card(
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: job.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: job.statusColor),
                    ),
                    child: Text(
                      job.statusLabel,
                      style: TextStyle(
                        color: job.statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Description
          Card(
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
                  Text(job.description),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Address
          Card(
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
                      Expanded(child: Text(job.address.fullAddress)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Dates
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _InfoRow(label: 'Created', value: job.formattedCreatedDate),
                  if (job.scheduledAt != null) ...[
                    const Divider(),
                    _InfoRow(
                      label: 'Scheduled',
                      value: job.formattedScheduledDate ?? '',
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Quotations Button (if quoted status or later)
          if (job.isQuoted ||
              job.isScheduled ||
              job.isInProgress ||
              job.isCompleted)
            unviewedCountAsync.when(
              data: (unviewedCount) => FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuotationsScreen(jobId: job.id),
                    ),
                  );
                },
                icon: const Icon(Icons.receipt_long),
                label: Text(
                  unviewedCount > 0
                      ? 'View Quotations ($unviewedCount new)'
                      : 'View Quotations',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: ColorConstants.seed,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuotationsScreen(jobId: job.id),
                    ),
                  );
                },
                icon: const Icon(Icons.receipt_long),
                label: const Text('View Quotations'),
              ),
            ),

          // Action Buttons
          if (job.canBeCancelled) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _showCancelDialog(context, ref, job.id),
              icon: const Icon(Icons.cancel),
              label: const Text('Cancel Job'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],

          if (job.canBeRescheduled) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _showRescheduleDialog(context, ref, job.id),
              icon: const Icon(Icons.schedule),
              label: const Text('Reschedule Job'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref, String jobId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Job'),
        content: const Text('Are you sure you want to cancel this job?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                final actions = ref.read(jobActionsProvider);
                await actions.cancelJob(jobId, 'Cancelled by client');

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Job cancelled')),
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
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _showRescheduleDialog(
    BuildContext context,
    WidgetRef ref,
    String jobId,
  ) {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reschedule Job'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select new date:'),
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
                final actions = ref.read(jobActionsProvider);
                await actions.rescheduleJob(jobId, selectedDate);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Job rescheduled')),
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
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

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