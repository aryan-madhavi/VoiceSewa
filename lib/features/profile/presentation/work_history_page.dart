import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_worker/core/extensions/context_extensions.dart';
import 'package:voicesewa_worker/features/profile/providers/work_history_provider.dart';
import 'package:voicesewa_worker/shared/models/job_model.dart';

class WorkHistoryPage extends ConsumerWidget {
  const WorkHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(completedJobsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          context.loc.workHistory,
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: jobsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading history: $e')),
        data: (jobs) {
          if (jobs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.work_history_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No completed jobs yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          // Summary totals
          final totalEarned = jobs.fold<double>(0, (sum, job) {
            return sum + _effectiveAmount(job);
          });

          return Column(
            children: [
              // ── Earnings summary bar ───────────────────────────────────
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Earned',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${totalEarned.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Jobs Done',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${jobs.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Job list ───────────────────────────────────────────────
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  itemCount: jobs.length,
                  itemBuilder: (context, index) =>
                      _JobHistoryCard(job: jobs[index]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Returns the best available amount for a completed job.
  /// Only count jobs that have a final bill (bill.totalAmount).
  /// Jobs without a bill are counted as 0 in the total.
  static double _effectiveAmount(JobModel job) {
    return job.bill?.totalAmount ?? 0;
  }
}

class _JobHistoryCard extends StatelessWidget {
  final JobModel job;
  const _JobHistoryCard({required this.job});

  /// Show only the final bill amount. Null if no bill exists yet.
  double? get _displayAmount => job.bill?.totalAmount;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Service icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: job.serviceColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(job.serviceIcon, color: job.serviceColor, size: 24),
          ),
          const SizedBox(width: 14),

          // Job info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.serviceName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  job.address.displayAddress,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  job.formattedScheduledDate ?? job.formattedCreatedDate,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                // Bill items count if available
                if (job.bill != null && job.bill!.items.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      '${job.bill!.items.length} item${job.bill!.items.length > 1 ? 's' : ''} billed',
                      style: const TextStyle(color: Colors.blue, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),

          // Amount + rating
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_displayAmount != null) ...[
                Text(
                  '₹${_displayAmount!.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
                Text(
                  'Final Bill',
                  style: TextStyle(fontSize: 10, color: Colors.green[700]),
                ),
              ],
              const SizedBox(height: 6),
              if (job.workerFeedback != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      job.workerFeedback!.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
