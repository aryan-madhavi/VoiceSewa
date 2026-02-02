import 'package:flutter/material.dart';
import 'package:voicesewa_client/core/constants/color_constants.dart';
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
            InfoRow(label: 'Created', value: createdDate),
            if (scheduledDate != null) ...[
              const Divider(),
              InfoRow(label: 'Scheduled', value: scheduledDate!),
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
        // View Quotations Button
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

        // Cancel Button
        if (job.canBeCancelled) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.cancel),
            label: const Text('Cancel Job'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],

        // Reschedule Button
        if (job.canBeRescheduled) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onReschedule,
            icon: const Icon(Icons.schedule),
            label: const Text('Reschedule Job'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ],
    );
  }
}
