import 'package:flutter/material.dart';
import 'package:voicesewa_client/core/constants/color_constants.dart';
import 'package:voicesewa_client/shared/models/quotation_model.dart';
import 'package:voicesewa_client/features/jobs/statusQueue/quotation_status_data.dart';

/// Worker info header with avatar, name, rating, and status
class QuotationWorkerHeader extends StatelessWidget {
  final Quotation quotation;

  const QuotationWorkerHeader({super.key, required this.quotation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        CircleAvatar(
          backgroundColor: ColorConstants.seed,
          child: Text(
            quotation.workerName.isNotEmpty
                ? quotation.workerName[0].toUpperCase()
                : 'W',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                quotation.workerName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              WorkerRating(rating: quotation.workerRating),
            ],
          ),
        ),
        QuotationStatusBadge(status: quotation.status),
      ],
    );
  }
}

/// Worker rating display
class WorkerRating extends StatelessWidget {
  final double rating;

  const WorkerRating({super.key, required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.star, size: 16, color: Colors.amber),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

/// Quotation status badge
class QuotationStatusBadge extends StatelessWidget {
  final QuotationStatus status;

  const QuotationStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: QuotationStatusData.getColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: QuotationStatusData.getColor(status)),
      ),
      child: Text(
        QuotationStatusData.getLabel(status),
        style: TextStyle(
          color: QuotationStatusData.getColor(status),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Quotation cost and time info chips
class QuotationEstimates extends StatelessWidget {
  final String cost;
  final String time;

  const QuotationEstimates({super.key, required this.cost, required this.time});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InfoChip(
            icon: Icons.currency_rupee,
            label: 'Cost',
            value: cost,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InfoChip(icon: Icons.access_time, label: 'Time', value: time),
        ),
      ],
    );
  }
}

/// Reusable info chip widget
class InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const InfoChip({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: ColorConstants.seed),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

/// Quotation description section
class QuotationDescription extends StatelessWidget {
  final String description;
  final String notes;

  const QuotationDescription({
    super.key,
    required this.description,
    required this.notes,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
        ),
        const SizedBox(height: 4),
        Text(description),
        if (notes.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            'Notes',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(notes),
        ],
      ],
    );
  }
}

/// Quotation action buttons (Accept/Reject)
class QuotationActionButtons extends StatelessWidget {
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const QuotationActionButtons({
    super.key,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onReject,
            icon: const Icon(Icons.cancel),
            label: const Text('Reject'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: onAccept,
            icon: const Icon(Icons.check_circle),
            label: const Text('Accept'),
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
          ),
        ),
      ],
    );
  }
}

/// Empty state for no quotations
class NoQuotationsPlaceholder extends StatelessWidget {
  const NoQuotationsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No quotations yet',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Workers will submit quotations soon',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
