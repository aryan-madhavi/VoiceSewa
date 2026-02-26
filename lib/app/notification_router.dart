import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_worker/core/constants/app_constants.dart';
import 'package:voicesewa_worker/core/providers/navbar_page_provider.dart';
import 'package:voicesewa_worker/features/jobs/presentation/job_details_page.dart';
import 'package:voicesewa_worker/features/jobs/presentation/widgets/my_job_card.dart';
import 'package:voicesewa_worker/features/jobs/providers/job_provider.dart';

class NotificationRouter {
  static Future<void> navigate(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> data,
  ) async {
    final type = data['type'] as String?;
    final jobId = data['job_id'] as String?;
    print('NotificationRouter type: $type | jobId: $jobId');

    switch (type) {
      case 'new_job':
        await _navigateToJobDetail(context, ref, jobId, JobTabType.incoming);
        break;

      case 'job_update':
      case 'booking':
        await _navigateToJobDetail(context, ref, jobId, JobTabType.ongoing);
        break;

      case 'earning':
        ref.read(navTabProvider.notifier).setTab(NavTab.earnings);
        break;

      case 'profile':
        ref.read(navTabProvider.notifier).setTab(NavTab.profile);
        break;

      default:
        ref.read(navTabProvider.notifier).setTab(NavTab.home);
        break;
    }
  }

  static Future<void> _navigateToJobDetail(
    BuildContext context,
    WidgetRef ref,
    String? jobId,
    JobTabType tabType,
  ) async {
    if (jobId == null || jobId.isEmpty) {
      ref.read(navTabProvider.notifier).setTab(NavTab.jobs);
      return;
    }

    final job = await ref.read(jobRepositoryProvider).fetchJob(jobId);
    if (!context.mounted) return;

    if (job == null) {
      ref.read(navTabProvider.notifier).setTab(NavTab.jobs);
      return;
    }

    // Set jobs tab as base so back button lands correctly
    ref.read(navTabProvider.notifier).setTab(NavTab.jobs);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            JobDetailPage(job: job, tabType: tabType, isDeclinedEntry: false),
      ),
    );
  }
}
