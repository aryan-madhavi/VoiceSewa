import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/core/constants/color_constants.dart';
import 'package:voicesewa_client/shared/models/job_model.dart';
import 'package:voicesewa_client/features/jobs/providers/job_provider.dart';
import 'package:voicesewa_client/features/jobs/presentation/create_job_screen.dart';
import 'package:voicesewa_client/features/jobs/presentation/job_details_screen.dart';

class BookAgainPage extends ConsumerWidget {
  const BookAgainPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(currentUserJobsProvider);

    return Scaffold(
      backgroundColor: ColorConstants.scaffold,
      appBar: AppBar(
        title: const Text('Book Again'),
        backgroundColor: ColorConstants.appBar,
      ),
      body: jobsAsync.when(
        data: (allJobs) {
          // Filter only completed jobs
          final completedJobs = allJobs.where((job) {
            return job.status == JobStatus.completed;
          }).toList();

          if (completedJobs.isEmpty) {
            return const _EmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: completedJobs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _CompletedJobCard(job: completedJobs[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          error: error.toString(),
          onRetry: () => ref.invalidate(currentUserJobsProvider),
        ),
      ),
    );
  }
}

// ==================== COMPLETED JOB CARD (MATCHING job_card.dart DESIGN) ====================

class _CompletedJobCard extends StatelessWidget {
  final Job job;

  const _CompletedJobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final color = job.statusColor;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service name and status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(job.serviceIcon, color: job.serviceColor, size: 16),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          job.serviceName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(status: job.statusLabel, color: color),
              ],
            ),

            const SizedBox(height: 10),

            // Worker name, rating, and date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 18,
                        color: Colors.black87,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          job.workerName ?? 'Worker not assigned',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      if (job.workerRating != null) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 3),
                        Text(
                          job.workerRating!.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  job.formattedCreatedDate,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Your rating and amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.star, size: 16, color: Colors.amber),
                    SizedBox(width: 4),
                    Text(
                      'Your Rating: —',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Text(
                  '₹${_getMockAmount(job)}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),

            const Divider(height: 20, color: Colors.grey),

            // Action buttons
            Center(
              child: Wrap(
                alignment: WrapAlignment.spaceAround,
                spacing: 8.0,
                runSpacing: 0.0,
                children: [
                  // Book Again button
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateJobScreen(
                            preselectedService: job.serviceType,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text(
                      'Book Again',
                      style: TextStyle(fontSize: 13),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: ColorConstants.seed,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: const Size(0, 36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),

                  // Invoice button
                  TextButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Invoice download coming soon'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text(
                      'Invoice',
                      style: TextStyle(fontSize: 13),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: const Size(0, 36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),

                  // Details button
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => JobDetailsScreen(jobId: job.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
                    label: const Text(
                      'Details',
                      style: TextStyle(fontSize: 13),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: const Size(0, 36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMockAmount(Job job) {
    // Mock amounts for demo - replace with actual amount from job
    return '1000';
  }
}

// ==================== STATUS BADGE ====================

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;

  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}

// ==================== EMPTY STATE ====================

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 100, color: Colors.grey.shade300),
            const SizedBox(height: 24),
            Text(
              'No Completed Jobs',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Once you complete a job, you can\neasily book the same service again',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateJobScreen()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Book a Service'),
              style: FilledButton.styleFrom(
                backgroundColor: ColorConstants.seed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== ERROR STATE ====================

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Failed to Load Jobs',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.seed,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
