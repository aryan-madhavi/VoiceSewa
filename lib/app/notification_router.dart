import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/core/providers/navbar_page_provider.dart';
import 'package:voicesewa_client/features/jobs/providers/job_provider.dart';
import 'package:voicesewa_client/features/jobs/presentation/job_details_screen.dart';
import 'package:voicesewa_client/features/quotations/prsentation/quotations_screen.dart';
import 'package:voicesewa_client/features/quotations/prsentation/chat_screen.dart';

class NotificationRouter {
  static Future<void> navigate(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> data,
  ) async {
    final type = data['type'] as String?;
    final jobId = data['job_id'] as String?;
    final quotationId = data['quotation_id'] as String?;
    final workerName = data['worker_name'] as String?;

    print(
      'NotificationRouter type: $type | jobId: $jobId | quotationId: $quotationId',
    );

    switch (type) {
      // ── New quotation received → open QuotationsScreen directly ──────────
      case 'new_quotation':
        _openQuotations(context, ref, jobId);
        break;

      // ── Quotation withdrawn → open JobDetailsScreen ───────────────────────
      case 'quotation_withdrawn':
        _openJobDetails(context, ref, jobId);
        break;

      // ── Job status changes → open JobDetailsScreen ────────────────────────
      case 'job_started':
      case 'job_completed':
        _openJobDetails(context, ref, jobId);
        break;

      // ── New message from worker → open ChatScreen directly ────────────────
      case 'new_message':
        await _openChat(context, ref, jobId, quotationId, workerName);
        break;

      default:
        ref.read(navTabProvider.notifier).setTab(NavTab.home);
        break;
    }
  }

  // ── Open QuotationsScreen ────────────────────────────────────────────────

  static void _openQuotations(
    BuildContext context,
    WidgetRef ref,
    String? jobId,
  ) {
    if (jobId == null || jobId.isEmpty) {
      print(
        '⚠️ NotificationRouter — no jobId for quotations, switching to history',
      );
      ref.read(navTabProvider.notifier).setTab(NavTab.history);
      return;
    }

    // Set history as base tab so back button lands there
    ref.read(navTabProvider.notifier).setTab(NavTab.history);

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => QuotationsScreen(jobId: jobId)));
  }

  // ── Open JobDetailsScreen ────────────────────────────────────────────────

  static void _openJobDetails(
    BuildContext context,
    WidgetRef ref,
    String? jobId,
  ) {
    if (jobId == null || jobId.isEmpty) {
      print('⚠️ NotificationRouter — no jobId, switching to history');
      ref.read(navTabProvider.notifier).setTab(NavTab.history);
      return;
    }

    // Set history as base tab so back button lands there
    ref.read(navTabProvider.notifier).setTab(NavTab.history);

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => JobDetailsScreen(jobId: jobId)));
  }

  // ── Open ChatScreen directly ─────────────────────────────────────────────

  static Future<void> _openChat(
    BuildContext context,
    WidgetRef ref,
    String? jobId,
    String? quotationId,
    String? workerName,
  ) async {
    if (jobId == null || jobId.isEmpty) {
      print('⚠️ NotificationRouter — no jobId for chat, switching to history');
      ref.read(navTabProvider.notifier).setTab(NavTab.history);
      return;
    }

    if (quotationId == null || quotationId.isEmpty) {
      // No quotation ID — fall back to job details
      print(
        '⚠️ NotificationRouter — no quotationId, falling back to job details',
      );
      _openJobDetails(context, ref, jobId);
      return;
    }

    // If worker_name wasn't in the payload, fetch it from the job
    String resolvedWorkerName = workerName ?? '';
    if (resolvedWorkerName.isEmpty) {
      final repository = ref.read(jobRepositoryProvider);
      final job = await repository.getJob(jobId);
      if (!context.mounted) return;
      resolvedWorkerName = job?.workerName ?? 'Worker';
    }

    // Set history as base tab so back button lands there
    ref.read(navTabProvider.notifier).setTab(NavTab.history);

    if (!context.mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          jobId: jobId,
          quotationId: quotationId,
          workerName: resolvedWorkerName,
        ),
      ),
    );
  }
}
