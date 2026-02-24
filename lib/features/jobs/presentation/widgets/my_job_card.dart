import 'package:flutter/material.dart';
import 'package:voicesewa_worker/core/constants/color_constants.dart';
import 'package:voicesewa_worker/core/constants/helper_function.dart';
import 'package:voicesewa_worker/features/jobs/presentation/job_details_page.dart';
import 'package:voicesewa_worker/shared/models/job_model.dart';

enum JobTabType { incoming, ongoing, completed }

class MyJobCard extends StatelessWidget {
  final JobModel job;
  final JobTabType tabType;
  // true when rendered inside the declined bucket — overrides status badge
  // and hides financial/rating info that is irrelevant for declined jobs.
  final bool isDeclined;

  const MyJobCard({
    super.key,
    required this.job,
    required this.tabType,
    this.isDeclined = false,
  });

  @override
  Widget build(BuildContext context) {
    // Declined bucket always shows red badge regardless of real job status
    final color = isDeclined ? ColorConstants.errorRed : job.statusColor;
    final badgeLabel = isDeclined ? 'Declined' : job.statusLabel;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shadowColor: ColorConstants.shadowBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header row ───────────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: job.serviceColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          job.serviceIcon,
                          size: 18,
                          color: job.serviceColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              job.serviceName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: ColorConstants.textDark,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Job #${job.jobId.substring(0, 6).toUpperCase()}',
                              style: const TextStyle(
                                color: ColorConstants.textGrey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusBadge(label: badgeLabel, color: color),
                    ],
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1),
                  ),

                  // ── Info rows ─────────────────────────────────────────────
                  myJobBuildIconText(
                    Icons.location_on_outlined,
                    job.address.displayAddress.isNotEmpty
                        ? job.address.displayAddress
                        : 'Location not specified',
                  ),
                  const SizedBox(height: 6),
                  myJobBuildIconText(
                    Icons.calendar_today_outlined,
                    job.createdAt != null
                        ? _formatDate(job.createdAt!)
                        : 'Date unknown',
                  ),
                  if (!isDeclined && job.finalizedQuotationAmount != null) ...[
                    const SizedBox(height: 6),
                    myJobBuildIconText(
                      Icons.payments_outlined,
                      '₹${job.finalizedQuotationAmount!.toStringAsFixed(0)}',
                      isBold: true,
                    ),
                  ],

                  const SizedBox(height: 14),

                  // ── Action button ─────────────────────────────────────────
                  _buildAction(context),
                ],
              ),
            ),

            // ── Left accent bar ───────────────────────────────────────────
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 5,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAction(BuildContext context) {
    switch (tabType) {
      case JobTabType.incoming:
      case JobTabType.ongoing:
        return _ActionButton(
          label: 'View Details',
          icon: Icons.remove_red_eye_outlined,
          color: ColorConstants.primaryBlue,
          onTap: () => _openDetails(context),
        );
      case JobTabType.completed:
        return _ActionButton(
          label: 'View Receipt',
          icon: Icons.receipt_long_outlined,
          color: ColorConstants.successGreen,
          outlined: true,
          onTap: () => _openDetails(context),
        );
    }
  }

  void _openDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => JobDetailPage(
          job: job,
          tabType: tabType,
          isDeclinedEntry: isDeclined,
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    const m = [
      '',
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
    return '${dt.day} ${m[dt.month]}, ${dt.year}';
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool outlined;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    );
    const padding = EdgeInsets.symmetric(vertical: 10);

    if (outlined) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          icon: Icon(icon, size: 16),
          label: Text(label),
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color),
            padding: padding,
            shape: shape,
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: ColorConstants.pureWhite,
          padding: padding,
          elevation: 0,
          shape: shape,
        ),
      ),
    );
  }
}
