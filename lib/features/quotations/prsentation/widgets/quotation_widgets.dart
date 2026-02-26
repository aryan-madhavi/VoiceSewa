import 'package:flutter/material.dart';
import 'package:voicesewa_client/core/constants/color_constants.dart';
import 'package:voicesewa_client/shared/models/quotation_model.dart';
import 'package:voicesewa_client/features/quotations/statusQueue/quotation_status_data.dart';

// ==================== HELPER ====================

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final hour = date.hour.toString().padLeft(2, '0');
  final min = date.minute.toString().padLeft(2, '0');
  return '${date.day} ${months[date.month - 1]} ${date.year}, $hour:$min';
}

// ==================== WORKER HEADER ====================

/// Worker info header with avatar, name, rating, status, and viewed indicator
class QuotationWorkerHeader extends StatelessWidget {
  final Quotation quotation;

  const QuotationWorkerHeader({super.key, required this.quotation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = quotation.workerName.trim().isNotEmpty
        ? quotation.workerName.trim()
        : 'Worker';
    final avatarLetter = displayName[0].toUpperCase();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: ColorConstants.seed,
              child: Text(
                avatarLetter,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            // ✅ Unread dot indicator
            if (!quotation.viewedByClient)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              WorkerRating(rating: quotation.workerRating),
              const SizedBox(height: 4),
              // ✅ Submitted date
              Text(
                'Submitted: ${_formatDate(quotation.createdAt)}',
                style: const TextStyle(fontSize: 11, color: Colors.black45),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            QuotationStatusBadge(status: quotation.status),
            // ✅ Auto-rejected badge
            if (quotation.autoRejected) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: const Text(
                  'Auto-rejected',
                  style: TextStyle(fontSize: 10, color: Colors.black54),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ==================== WORKER RATING ====================

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
        const SizedBox(width: 4),
        const Text(
          'rating',
          style: TextStyle(fontSize: 11, color: Colors.black45),
        ),
      ],
    );
  }
}

// ==================== STATUS BADGE ====================

class QuotationStatusBadge extends StatelessWidget {
  final QuotationStatus status;

  const QuotationStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

// ==================== ESTIMATES ====================

/// Quotation cost, time, and availability chips
class QuotationEstimates extends StatelessWidget {
  final String cost;
  final String time;
  final String availability;

  const QuotationEstimates({
    super.key,
    required this.cost,
    required this.time,
    required this.availability,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: InfoChip(
                icon: Icons.currency_rupee,
                label: 'Est. Cost',
                value: cost,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InfoChip(
                icon: Icons.access_time,
                label: 'Est. Time',
                value: time,
              ),
            ),
          ],
        ),
        if (availability.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.event_available,
                  size: 18,
                  color: Colors.green.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Availability',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        availability,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.green.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ==================== INFO CHIP ====================

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

// ==================== DESCRIPTION + NOTES + PRICE BREAKDOWN ====================

/// Quotation description, notes, price breakdown, and status-based info
class QuotationDescription extends StatelessWidget {
  final Quotation quotation;

  const QuotationDescription({super.key, required this.quotation});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description
        const Text(
          'Description',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
        ),
        const SizedBox(height: 4),
        Text(quotation.description),

        // Notes
        if (quotation.notes.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            'Notes',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(quotation.notes),
        ],

        // ✅ Price Breakdown
        if (quotation.priceBreakdown != null &&
            quotation.priceBreakdown!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _PriceBreakdownSection(breakdown: quotation.priceBreakdown!),
        ],

        // ✅ Timestamps section based on status
        const SizedBox(height: 12),
        _QuotationTimestamps(quotation: quotation),

        // ✅ Rejection reason
        if (quotation.isRejected && quotation.rejectionReason != null) ...[
          const SizedBox(height: 12),
          _ReasonBanner(
            icon: Icons.cancel_outlined,
            label: 'Rejection Reason',
            reason: quotation.rejectionReason!,
            color: Colors.red,
          ),
        ],

        // ✅ Withdrawal reason
        if (quotation.isWithdrawn && quotation.withdrawalReason != null) ...[
          const SizedBox(height: 12),
          _ReasonBanner(
            icon: Icons.undo,
            label: 'Withdrawal Reason',
            reason: quotation.withdrawalReason!,
            color: Colors.orange,
          ),
        ],
      ],
    );
  }
}

// ==================== PRICE BREAKDOWN ====================

class _PriceBreakdownSection extends StatelessWidget {
  final Map<String, dynamic> breakdown;

  const _PriceBreakdownSection({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Price Breakdown',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: breakdown.entries.map((entry) {
              final isLast = entry.key == breakdown.keys.last;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key, style: const TextStyle(fontSize: 13)),
                        Text(
                          '₹${entry.value}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast) const Divider(height: 1),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ==================== TIMESTAMPS ====================

class _QuotationTimestamps extends StatelessWidget {
  final Quotation quotation;

  const _QuotationTimestamps({required this.quotation});

  @override
  Widget build(BuildContext context) {
    final entries = <_TimestampEntry>[];

    if (quotation.viewedAt != null) {
      entries.add(
        _TimestampEntry(
          icon: Icons.visibility_outlined,
          label: 'Viewed',
          date: quotation.viewedAt!,
          color: Colors.blue,
        ),
      );
    }
    if (quotation.acceptedAt != null) {
      entries.add(
        _TimestampEntry(
          icon: Icons.check_circle_outline,
          label: 'Accepted',
          date: quotation.acceptedAt!,
          color: Colors.green,
        ),
      );
    }
    if (quotation.rejectedAt != null) {
      entries.add(
        _TimestampEntry(
          icon: Icons.cancel_outlined,
          label: 'Rejected',
          date: quotation.rejectedAt!,
          color: Colors.red,
        ),
      );
    }
    if (quotation.withdrawnAt != null) {
      entries.add(
        _TimestampEntry(
          icon: Icons.undo,
          label: 'Withdrawn',
          date: quotation.withdrawnAt!,
          color: Colors.orange,
        ),
      );
    }
    if (quotation.updatedAt != null) {
      entries.add(
        _TimestampEntry(
          icon: Icons.update,
          label: 'Updated',
          date: quotation.updatedAt!,
          color: Colors.grey,
        ),
      );
    }

    if (entries.isEmpty) return const SizedBox.shrink();

    return Column(
      children: entries.map((e) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Icon(e.icon, size: 14, color: e.color),
              const SizedBox(width: 6),
              Text(
                '${e.label}: ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: e.color,
                ),
              ),
              Text(
                _formatDate(e.date),
                style: const TextStyle(fontSize: 11, color: Colors.black45),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _TimestampEntry {
  final IconData icon;
  final String label;
  final DateTime date;
  final Color color;

  _TimestampEntry({
    required this.icon,
    required this.label,
    required this.date,
    required this.color,
  });
}

// ==================== REASON BANNER ====================

class _ReasonBanner extends StatelessWidget {
  final IconData icon;
  final String label;
  final String reason;
  final Color color;

  const _ReasonBanner({
    required this.icon,
    required this.label,
    required this.reason,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reason,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== ACTION BUTTONS ====================

class QuotationActionButtons extends StatelessWidget {
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onContact;

  const QuotationActionButtons({
    super.key,
    required this.onAccept,
    required this.onReject,
    required this.onContact,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onReject,
                icon: const Icon(Icons.cancel, size: 18),
                label: const Text('Reject'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: onAccept,
                icon: const Icon(Icons.check_circle, size: 18),
                label: const Text('Accept'),
                style: FilledButton.styleFrom(backgroundColor: Colors.green),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onContact,
            icon: const Icon(Icons.chat_bubble_outline, size: 18),
            label: const Text('Contact Worker'),
            style: OutlinedButton.styleFrom(
              foregroundColor: ColorConstants.seed,
              side: const BorderSide(color: ColorConstants.seed),
            ),
          ),
        ),
      ],
    );
  }
}

// ==================== CONTACT BUTTON (for non-pending quotations) ====================

/// Shown on accepted quotation (chat enabled) or disabled on others
class QuotationContactButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback? onContact;

  const QuotationContactButton({
    super.key,
    required this.enabled,
    this.onContact,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: enabled ? onContact : null,
        icon: const Icon(Icons.chat_bubble_outline, size: 18),
        label: Text(enabled ? 'Open Chat' : 'Chat Unavailable'),
        style: OutlinedButton.styleFrom(
          foregroundColor: enabled ? ColorConstants.seed : Colors.grey,
          side: BorderSide(
            color: enabled ? ColorConstants.seed : Colors.grey.shade300,
          ),
        ),
      ),
    );
  }
}

// ==================== EMPTY STATE ====================

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
