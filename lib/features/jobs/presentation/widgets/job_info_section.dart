import 'package:flutter/material.dart';
import 'package:voicesewa_worker/core/constants/color_constants.dart';
import 'package:voicesewa_worker/shared/models/job_model.dart';
import 'job_section_card.dart';

class JobInfoSection extends StatelessWidget {
  final JobModel job;

  const JobInfoSection({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    return JobSectionCard(
      title: 'Job Details',
      icon: Icons.description_outlined,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            JobDetailRow(Icons.build_outlined, 'Service', job.serviceName),
            if (job.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              JobDetailRow(
                Icons.notes_outlined,
                'Description',
                job.description,
              ),
            ],
            if (job.createdAt != null) ...[
              const SizedBox(height: 10),
              JobDetailRow(
                Icons.access_time,
                'Posted',
                _formatDateTime(job.createdAt!),
              ),
            ],
            if (job.scheduledAt != null) ...[
              const SizedBox(height: 10),
              JobDetailRow(
                Icons.event_outlined,
                'Scheduled',
                _formatDateTime(job.scheduledAt!),
              ),
            ],
            if (job.finalizedQuotationAmount != null) ...[
              const SizedBox(height: 10),
              JobDetailRow(
                Icons.payments_outlined,
                'Agreed Amount',
                '₹${job.finalizedQuotationAmount!.toStringAsFixed(0)}',
                valueColor: ColorConstants.primaryBlue,
                valueBold: true,
              ),
            ],
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
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
    final h = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
        ? 12
        : dt.hour;
    final min = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day} ${m[dt.month]} ${dt.year}, $h:$min $period';
  }
}
