import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_worker/core/constants/color_constants.dart';
import 'package:voicesewa_worker/core/constants/string_constants.dart';
import 'package:voicesewa_worker/features/earnings/providers/earnings_provider.dart';
import 'package:voicesewa_worker/shared/models/job_model.dart';

class TransactionHistory extends ConsumerWidget {
  const TransactionHistory({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earningsAsync = ref.watch(earningsDataProvider);

    return earningsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text('Could not load transactions',
              style: TextStyle(color: Colors.grey[500])),
        ),
      ),
      data: (data) {
        final jobs = data.billedJobs;

        if (jobs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  Text(
                    'No transactions yet',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          separatorBuilder: (_, __) =>
              const Divider(height: 1, indent: 60),
          itemCount: jobs.length,
          itemBuilder: (_, index) => _TransactionTile(job: jobs[index]),
        );
      },
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final JobModel job;
  const _TransactionTile({required this.job});

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final jobDay = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(jobDay).inDays;

    final time =
        '${dt.hour % 12 == 0 ? 12 : dt.hour % 12}:${dt.minute.toString().padLeft(2, '0')} '
        '${dt.hour >= 12 ? 'PM' : 'AM'}';

    if (diff == 0) return 'Today, $time';
    if (diff == 1) return 'Yesterday, $time';
    return '${dt.day} ${months[dt.month - 1]}, $time';
  }

  @override
  Widget build(BuildContext context) {
    final amount = job.bill!.totalAmount;
    final date = job.scheduledAt ?? job.createdAt;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: job.serviceColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(job.serviceIcon, color: job.serviceColor, size: 20),
      ),
      title: Text(
        job.serviceName,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        '${_formatDate(date)} · Completed',
        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
      ),
      trailing: Text(
        '+ ${StringConstants.rupee}${amount.toInt()}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: Colors.green[700],
        ),
      ),
    );
  }
}