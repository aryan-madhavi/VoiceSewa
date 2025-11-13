import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:voicesewa_client/core/constants/helper_functions.dart';
import 'package:voicesewa_client/features/history/presentation/widgets/status_badge.dart';

class RecentRequestCard extends StatelessWidget {
  const RecentRequestCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Replace with Future
    final List<Map<String, String>> recentRequests = [
      {
        'title': 'Kitchen tap repair',
        'worker': 'Rajesh K.',
        'eta': '30 mins',
        'status': 'Pending',
      },
      {
        'title': 'AC service',
        'worker': 'Anita S.',
        'eta': 'In Progress',
        'status': 'In Progress',
      },
      {
        'title': 'Light fixture install',
        'worker': 'Kumar P.',
        'eta': 'Cancelled',
        'status': 'Cancelled',
      },
      {
        'title': 'Light fixture install',
        'worker': 'Sunil T.',
        'eta': 'Completed',
        'status': 'Completed',
      },
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 16),
              child: Text(
                'Track Recent Requests',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),

            ListView.separated(
              itemCount: recentRequests.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final req = recentRequests[index];
                final status = req['status']!;
                final color = Helpers.getStatusColor(status);

                return _RecentRequestTile(
                  title: req['title']!,
                  worker: req['worker']!,
                  eta: req['eta']!,
                  status: status,
                  color: color,
                  onTap: () => context.pushNamedTransition(
                    routeName: Helpers.getValidRoute('/trackWorker'),
                    type: PageTransitionType.rightToLeft,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentRequestTile extends StatelessWidget {
  final String title;
  final String worker;
  final String eta;
  final String status;
  final Color color;
  final VoidCallback onTap;

  const _RecentRequestTile({
    required this.title,
    required this.worker,
    required this.eta,
    required this.status,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            //Left status bar
            Container(
              width: 6,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),

            const SizedBox(width: 12),

            // Main details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Worker: $worker',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.black54,
                    ),
                  ),
                  Text(
                    'ETA: $eta',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            StatusBadge(status: status, color: color),
          ],
        ),
      ),
    );
  }
}
