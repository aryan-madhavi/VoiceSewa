import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_worker/core/constants/app_constants.dart';
import 'package:voicesewa_worker/core/providers/navbar_page_provider.dart';
import 'package:voicesewa_worker/features/jobs/presentation/chat_page.dart';
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
    final quotationId = data['quotation_id'] as String?;
    print('NotificationRouter type: $type | jobId: $jobId | quotationId: $quotationId');

    switch (type) {
      // ── New job nearby → incoming job detail ────────────────────────────
      case 'new_job':
        await _openJobDetail(context, ref, jobId, JobTabType.incoming);
        break;

      // ── Quotation accepted/rejected → incoming job detail ────────────────
      case 'quotation_accepted':
      case 'quotation_rejected':
        await _openJobDetail(context, ref, jobId, JobTabType.incoming);
        break;

      // ── Job scheduled/rescheduled → ongoing job detail ───────────────────
      case 'job_scheduled':
      case 'job_rescheduled':
      case 'job_update':
        await _openJobDetail(context, ref, jobId, JobTabType.ongoing);
        break;

      // ── Job completed → completed job detail ─────────────────────────────
      case 'job_completed':
        await _openJobDetail(context, ref, jobId, JobTabType.completed);
        break;

      // ── Job cancelled → incoming job detail ──────────────────────────────
      case 'job_cancelled':
        await _openJobDetail(context, ref, jobId, JobTabType.incoming);
        break;

      // ── New message → open chat directly ─────────────────────────────────
      case 'new_message':
        await _openChat(context, ref, jobId, quotationId);
        break;

      // ── Earnings / profile tab switches ──────────────────────────────────
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

  // ── Open JobDetailPage with correct tab ──────────────────────────────────

  static Future<void> _openJobDetail(
    BuildContext context,
    WidgetRef ref,
    String? jobId,
    JobTabType tabType,
  ) async {
    if (jobId == null || jobId.isEmpty) {
      print('⚠️ NotificationRouter — no jobId, switching to jobs tab');
      ref.read(navTabProvider.notifier).setTab(NavTab.jobs);
      return;
    }

    final job = await ref.read(jobRepositoryProvider).fetchJob(jobId);
    if (!context.mounted) return;

    if (job == null) {
      print('⚠️ NotificationRouter — job not found, switching to jobs tab');
      ref.read(navTabProvider.notifier).setTab(NavTab.jobs);
      return;
    }

    // Set correct base tab so back button lands in the right place
    final baseTab = tabType == JobTabType.completed
        ? NavTab.jobs  // completed lives in jobs tab too
        : NavTab.jobs;
    ref.read(navTabProvider.notifier).setTab(baseTab);

    if (!context.mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => JobDetailPage(
          job: job,
          tabType: tabType,
          isDeclinedEntry: false,
        ),
      ),
    );
  }

  // ── Open ChatPage directly ───────────────────────────────────────────────

  static Future<void> _openChat(
    BuildContext context,
    WidgetRef ref,
    String? jobId,
    String? quotationId,
  ) async {
    if (jobId == null || jobId.isEmpty) {
      print('⚠️ NotificationRouter — no jobId for chat, switching to jobs tab');
      ref.read(navTabProvider.notifier).setTab(NavTab.jobs);
      return;
    }

    if (quotationId == null || quotationId.isEmpty) {
      print('⚠️ NotificationRouter — no quotationId for chat, opening job detail');
      await _openJobDetail(context, ref, jobId, JobTabType.incoming);
      return;
    }

    final job = await ref.read(jobRepositoryProvider).fetchJob(jobId);
    if (!context.mounted) return;

    if (job == null) {
      print('⚠️ NotificationRouter — job not found for chat, switching to jobs tab');
      ref.read(navTabProvider.notifier).setTab(NavTab.jobs);
      return;
    }

    ref.read(navTabProvider.notifier).setTab(NavTab.jobs);
    if (!context.mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatPage(
          job: job,
          quotationId: quotationId,
        ),
      ),
    );
  }
}