import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_worker/core/constants/color_constants.dart';
import 'package:voicesewa_worker/features/jobs/providers/job_provider.dart';
import 'package:voicesewa_worker/features/jobs/presentation/widgets/my_job_card.dart';
import 'package:voicesewa_worker/features/profile/providers/worker_profile_provider.dart';
import 'package:voicesewa_worker/shared/models/job_model.dart';
import 'job_filter_bar.dart';
import 'job_empty_state.dart';
import 'job_card_skeleton.dart';
import 'service_filter_row.dart';

class OngoingJobsTab extends ConsumerStatefulWidget {
  final String sort;
  final ValueChanged<String> onSortChanged;
  final List<JobModel> Function(List<JobModel>, String) sortJobs;
  final List<String> sortOptions;

  const OngoingJobsTab({
    super.key,
    required this.sort,
    required this.onSortChanged,
    required this.sortJobs,
    required this.sortOptions,
  });

  @override
  ConsumerState<OngoingJobsTab> createState() => _OngoingJobsTabState();
}

class _OngoingJobsTabState extends ConsumerState<OngoingJobsTab> {
  // null = All, 'today' = scheduled today, 'upcoming' = future scheduled,
  // 'inProgress' = already started
  String? _statusFilter;

  // null = all services
  String? _serviceFilter;

  List<JobModel> _applyFilters(List<JobModel> jobs) {
    // Step 1: status
    List<JobModel> base;
    switch (_statusFilter) {
      case 'today':
        base = jobs.where((j) => j.isScheduled && j.isScheduledToday).toList();
        break;
      case 'upcoming':
        base = jobs
            .where(
              (j) => (j.isScheduled || j.isRescheduled) && !j.isScheduledToday,
            )
            .toList();
        break;
      case 'inProgress':
        base = jobs.where((j) => j.isInProgress).toList();
        break;
      default:
        base = jobs;
    }
    // Step 2: service
    if (_serviceFilter != null) {
      base = base.where((j) => j.serviceName == _serviceFilter).toList();
    }
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final ongoing = ref.watch(ongoingJobsProvider);
    final uid = ref.watch(currentWorkerUidProvider);
    final profileAsync = ref.watch(workerProfileStreamProvider(uid));

    final ongoingJobs = ongoing.value ?? [];
    final workerSkills = profileAsync.value?.skills ?? [];

    // Service counts relative to active status bucket
    final serviceCountPool = _applyStatusFilter(ongoingJobs);

    return Column(
      children: [
        JobFilterBar(
          sort: widget.sort,
          onSortChanged: widget.onSortChanged,
          sortOptions: widget.sortOptions,
        ),
        _buildStatusChips(ongoingJobs),
        ServiceFilterRow(
          skills: workerSkills,
          jobs: serviceCountPool,
          selectedService: _serviceFilter,
          onSelected: (s) => setState(() => _serviceFilter = s),
        ),
        const Divider(height: 1),
        Expanded(
          child: ongoing.when(
            loading: () => const JobListSkeleton(),
            error: (e, _) => RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(ongoingJobsProvider);
                await Future.delayed(const Duration(milliseconds: 800));
              },
              child: ListView(
                children: [
                  SizedBox(
                    height: 300,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 40,
                            color: ColorConstants.textGrey,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Error: $e',
                            style: const TextStyle(
                              color: ColorConstants.textGrey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Pull down to retry',
                            style: TextStyle(
                              fontSize: 12,
                              color: ColorConstants.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            data: (jobs) {
              final filtered = _applyFilters(jobs);
              if (filtered.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(ongoingJobsProvider);
                    await Future.delayed(const Duration(milliseconds: 800));
                  },
                  child: ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.55,
                        child: JobEmptyState(
                          icon: Icons.work_outline,
                          title: _emptyTitle(),
                          subtitle: _emptySubtitle(),
                        ),
                      ),
                    ],
                  ),
                );
              }
              final sorted = widget.sortJobs(filtered, widget.sort);
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(ongoingJobsProvider);
                  await Future.delayed(const Duration(milliseconds: 800));
                },
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: sorted.length,
                  itemBuilder: (_, i) =>
                      MyJobCard(job: sorted[i], tabType: JobTabType.ongoing),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Apply only the status part (used for computing service chip counts)
  List<JobModel> _applyStatusFilter(List<JobModel> jobs) {
    switch (_statusFilter) {
      case 'today':
        return jobs.where((j) => j.isScheduled && j.isScheduledToday).toList();
      case 'upcoming':
        return jobs
            .where(
              (j) => (j.isScheduled || j.isRescheduled) && !j.isScheduledToday,
            )
            .toList();
      case 'inProgress':
        return jobs.where((j) => j.isInProgress).toList();
      default:
        return jobs;
    }
  }

  // ── Empty state helpers ──────────────────────────────────────────────────

  String _emptyTitle() {
    if (_serviceFilter != null && _statusFilter != null) {
      return 'No ${_statusFilterLabel()} $_serviceFilter Jobs';
    }
    if (_serviceFilter != null) return 'No $_serviceFilter Jobs';
    switch (_statusFilter) {
      case 'today':
        return 'Nothing Scheduled Today';
      case 'upcoming':
        return 'No Upcoming Jobs';
      case 'inProgress':
        return 'No Jobs In Progress';
      default:
        return 'No Active Jobs';
    }
  }

  String _emptySubtitle() {
    if (_serviceFilter != null) return 'No ongoing jobs for this service.';
    switch (_statusFilter) {
      case 'today':
        return 'No jobs are scheduled for today.';
      case 'upcoming':
        return 'Future scheduled jobs will appear here.';
      case 'inProgress':
        return 'Start a job to see it here.';
      default:
        return 'Jobs you\'ve been confirmed for\nwill appear here.';
    }
  }

  String _statusFilterLabel() {
    switch (_statusFilter) {
      case 'today':
        return 'Today\'s';
      case 'upcoming':
        return 'Upcoming';
      case 'inProgress':
        return 'In Progress';
      default:
        return '';
    }
  }

  // ── Status chips (row 1) ─────────────────────────────────────────────────

  Widget _buildStatusChips(List<JobModel> jobs) {
    final todayCount = jobs
        .where((j) => j.isScheduled && j.isScheduledToday)
        .length;
    final upcomingCount = jobs
        .where((j) => (j.isScheduled || j.isRescheduled) && !j.isScheduledToday)
        .length;
    final inProgressCount = jobs.where((j) => j.isInProgress).length;

    return Container(
      color: ColorConstants.pureWhite,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _OngoingChip(
              label: 'All',
              count: jobs.length,
              selected: _statusFilter == null,
              color: ColorConstants.primaryBlue,
              icon: Icons.list_outlined,
              onTap: () => setState(() => _statusFilter = null),
            ),
            const SizedBox(width: 8),
            _OngoingChip(
              label: 'Today',
              count: todayCount,
              selected: _statusFilter == 'today',
              color: ColorConstants.successTeal,
              icon: Icons.today_outlined,
              onTap: () => setState(() => _statusFilter = 'today'),
            ),
            const SizedBox(width: 8),
            _OngoingChip(
              label: 'Upcoming',
              count: upcomingCount,
              selected: _statusFilter == 'upcoming',
              color: ColorConstants.primaryBlue,
              icon: Icons.event_outlined,
              onTap: () => setState(() => _statusFilter = 'upcoming'),
            ),
            const SizedBox(width: 8),
            _OngoingChip(
              label: 'In Progress',
              count: inProgressCount,
              selected: _statusFilter == 'inProgress',
              color: ColorConstants.chipOrange,
              icon: Icons.play_circle_outline,
              onTap: () => setState(() => _statusFilter = 'inProgress'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Ongoing status chip ───────────────────────────────────────────────────

class _OngoingChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _OngoingChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? color.withOpacity(0.12)
              : ColorConstants.chipGreySurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : ColorConstants.chipGreyBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: selected ? color : ColorConstants.textGrey,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? color : ColorConstants.textGrey,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: selected ? color : ColorConstants.chipGreyBadge,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 10,
                    color: ColorConstants.pureWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
