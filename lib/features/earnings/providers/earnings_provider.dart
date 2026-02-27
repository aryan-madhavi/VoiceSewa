import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_worker/core/providers/session_provider.dart';
import 'package:voicesewa_worker/features/profile/providers/worker_profile_provider.dart';
import 'package:voicesewa_worker/shared/models/job_model.dart';

// ── Earnings data model ────────────────────────────────────────────────────

class MonthlyEarning {
  final int year;
  final int month; // 1–12
  final double amount;

  const MonthlyEarning({
    required this.year,
    required this.month,
    required this.amount,
  });

  /// Short label for chart x-axis: "Jan", "Feb", etc.
  String get monthLabel {
    const labels = [
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
    return labels[month - 1];
  }

  /// Full label for tooltip: "Jan 2024"
  String get fullLabel => '$monthLabel $year';
}

class EarningsData {
  /// All completed jobs that have a bill (bill.totalAmount is the source of truth)
  final List<JobModel> billedJobs;

  /// Monthly breakdown — all time, sorted oldest → newest
  final List<MonthlyEarning> monthlyEarnings;

  /// Total earned across all time (sum of bill.totalAmount)
  final double totalEarned;

  /// Pending amount — sum of finalizedQuotationAmount for scheduled/inProgress jobs
  final double pendingAmount;

  const EarningsData({
    required this.billedJobs,
    required this.monthlyEarnings,
    required this.totalEarned,
    required this.pendingAmount,
  });

  static const empty = EarningsData(
    billedJobs: [],
    monthlyEarnings: [],
    totalEarned: 0,
    pendingAmount: 0,
  );
}

// ── Completed jobs provider (earnings scope) ──────────────────────────────

final _earningsJobsProvider = FutureProvider.autoDispose<List<JobModel>>((
  ref,
) async {
  final uid = ref.watch(currentUserProvider)?.uid ?? '';
  if (uid.isEmpty) return [];

  final profileAsync = ref.watch(workerProfileStreamProvider(uid));
  final worker = profileAsync.when(
    data: (w) => w,
    loading: () => null,
    error: (_, __) => null,
  );
  if (worker == null) return [];

  // Fetch completed + confirmed refs in parallel
  final allRefs = [...worker.jobs.completed, ...worker.jobs.confirmed];
  if (allRefs.isEmpty) return [];

  final snapshots = await Future.wait(allRefs.map((r) => r.get()));
  return snapshots
      .where((doc) => doc.exists)
      .map((doc) => JobModel.fromDoc(doc))
      .toList();
});

// ── Derived EarningsData provider ─────────────────────────────────────────

final earningsDataProvider = FutureProvider.autoDispose<EarningsData>((
  ref,
) async {
  final jobs = await ref.watch(_earningsJobsProvider.future);
  if (jobs.isEmpty) return EarningsData.empty;

  // ── Completed billed jobs ────────────────────────────────────────────────
  final billedJobs = jobs.where((j) => j.isCompleted && j.bill != null).toList()
    ..sort((a, b) {
      final aDate = a.scheduledAt ?? a.createdAt;
      final bDate = b.scheduledAt ?? b.createdAt;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate); // most recent first
    });

  // ── Total earned ─────────────────────────────────────────────────────────
  final totalEarned = billedJobs.fold<double>(
    0,
    (sum, j) => sum + j.bill!.totalAmount,
  );

  // ── Pending: scheduled or inProgress jobs with a quotation amount ────────
  final pendingAmount = jobs
      .where(
        (j) =>
            (j.isScheduled || j.isInProgress) &&
            j.finalizedQuotationAmount != null,
      )
      .fold<double>(0, (sum, j) => sum + j.finalizedQuotationAmount!);

  // ── Monthly earnings grouped by year+month ───────────────────────────────
  final Map<String, double> monthMap = {};
  for (final job in billedJobs) {
    final date = job.scheduledAt ?? job.createdAt;
    if (date == null) continue;
    final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
    monthMap[key] = (monthMap[key] ?? 0) + job.bill!.totalAmount;
  }

  final monthlyEarnings =
      monthMap.entries.map((e) {
        final parts = e.key.split('-');
        return MonthlyEarning(
          year: int.parse(parts[0]),
          month: int.parse(parts[1]),
          amount: e.value,
        );
      }).toList()..sort((a, b) {
        final aVal = a.year * 100 + a.month;
        final bVal = b.year * 100 + b.month;
        return aVal.compareTo(bVal); // oldest → newest for chart
      });

  return EarningsData(
    billedJobs: billedJobs,
    monthlyEarnings: monthlyEarnings,
    totalEarned: totalEarned,
    pendingAmount: pendingAmount,
  );
});
