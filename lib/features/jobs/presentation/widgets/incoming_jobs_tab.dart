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

class IncomingJobsTab extends ConsumerStatefulWidget {
  final String sort;
  final ValueChanged<String> onSortChanged;
  final List<JobModel> Function(List<JobModel>, String) sortJobs;
  final List<String> sortOptions;

  const IncomingJobsTab({
    super.key,
    required this.sort,
    required this.onSortChanged,
    required this.sortJobs,
    required this.sortOptions,
  });

  @override
  ConsumerState<IncomingJobsTab> createState() => _IncomingJobsTabState();
}

class _IncomingJobsTabState extends ConsumerState<IncomingJobsTab> {
  // null = All, 'new' = requested only, 'quoted' = quoted only,
  // 'declined' = declined list
  String? _statusFilter;

  // null = all services
  String? _serviceFilter;

  /// Filters the incoming list to exclude any job that is also in the declined
  /// list (i.e. rejected by client or auto-rejected). Those belong only in the
  /// Declined bucket.
  List<JobModel> _cleanIncoming(
    List<JobModel> incoming,
    List<JobModel> declined,
  ) {
    final declinedIds = declined.map((j) => j.jobId).toSet();
    return incoming.where((j) => !declinedIds.contains(j.jobId)).toList();
  }

  List<JobModel> _applyFilters(
    List<JobModel> incoming,
    List<JobModel> declined,
  ) {
    final clean = _cleanIncoming(incoming, declined);

    // Step 1: status
    List<JobModel> base;
    switch (_statusFilter) {
      case 'new':
        base = clean.where((j) => j.isRequested).toList();
        break;
      case 'quoted':
        base = clean.where((j) => j.isQuoted).toList();
        break;
      case 'declined':
        base = declined;
        break;
      default:
        base = clean;
    }
    // Step 2: service
    if (_serviceFilter != null) {
      base = base.where((j) => j.serviceName == _serviceFilter).toList();
    }
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final incoming = ref.watch(incomingJobsProvider);
    final declinedAsync = ref.watch(incomingDeclinedJobsProvider);
    final uid = ref.watch(currentWorkerUidProvider);
    final profileAsync = ref.watch(workerProfileStreamProvider(uid));

    final incomingJobs = incoming.value ?? [];
    final declinedJobs = declinedAsync.value ?? [];
    final workerSkills = profileAsync.value?.skills ?? [];

    // Clean incoming before computing chip counts
    final cleanIncoming = _cleanIncoming(incomingJobs, declinedJobs);

    // Service chip counts are always relative to the currently active
    // status bucket — so chips show how many of each service exist
    // within the selected status view.
    final serviceCountPool = _statusFilter == 'declined'
        ? declinedJobs
        : _statusFilter == 'new'
        ? cleanIncoming.where((j) => j.isRequested).toList()
        : _statusFilter == 'quoted'
        ? cleanIncoming.where((j) => j.isQuoted).toList()
        : cleanIncoming;

    return Column(
      children: [
        JobFilterBar(
          sort: widget.sort,
          onSortChanged: widget.onSortChanged,
          sortOptions: widget.sortOptions,
        ),
        _buildStatusChips(cleanIncoming, declinedJobs),
        ServiceFilterRow(
          skills: workerSkills,
          jobs: serviceCountPool,
          selectedService: _serviceFilter,
          onSelected: (s) => setState(() => _serviceFilter = s),
        ),
        const Divider(height: 1),
        Expanded(
          child: _statusFilter == 'declined'
              ? _buildDeclinedList(declinedAsync, declinedJobs)
              : incoming.when(
                  loading: () => const JobListSkeleton(),
                  error: (e, _) => RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(incomingJobsProvider);
                      ref.invalidate(incomingDeclinedJobsProvider);
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
                    final filtered = _applyFilters(jobs, declinedJobs);
                    if (filtered.isEmpty) {
                      return JobEmptyState(
                        icon: Icons.inbox_outlined,
                        title: _emptyTitle(),
                        subtitle: _emptySubtitle(),
                      );
                    }
                    final sorted = widget.sortJobs(filtered, widget.sort);
                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(incomingJobsProvider);
                        ref.invalidate(incomingDeclinedJobsProvider);
                        await Future.delayed(const Duration(milliseconds: 800));
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        itemCount: sorted.length,
                        itemBuilder: (_, i) => MyJobCard(
                          job: sorted[i],
                          tabType: JobTabType.incoming,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ── Empty state helpers ──────────────────────────────────────────────────

  String _emptyTitle() {
    if (_serviceFilter != null && _statusFilter != null) {
      return 'No ${_statusFilterLabel()} $_serviceFilter Jobs';
    }
    if (_serviceFilter != null) return 'No $_serviceFilter Jobs';
    if (_statusFilter == 'new') return 'No New Jobs';
    if (_statusFilter == 'quoted') return 'No Quoted Jobs';
    return 'No Incoming Jobs';
  }

  String _emptySubtitle() {
    if (_serviceFilter != null) return 'No jobs for this service right now.';
    if (_statusFilter == null) {
      return 'New jobs matching your skills\nwill appear here.';
    }
    return 'No jobs in this category.';
  }

  String _statusFilterLabel() {
    switch (_statusFilter) {
      case 'new':
        return 'New';
      case 'quoted':
        return 'Quoted';
      case 'declined':
        return 'Declined';
      default:
        return '';
    }
  }

  // ── Declined list ────────────────────────────────────────────────────────

  Widget _buildDeclinedList(
    AsyncValue<List<JobModel>> declinedAsync,
    List<JobModel> declinedJobs,
  ) {
    if (declinedAsync.isLoading) {
      return const JobListSkeleton();
    }
    if (declinedAsync.hasError) {
      return Center(child: Text('Error: ${declinedAsync.error}'));
    }
    final filtered = _serviceFilter != null
        ? declinedJobs.where((j) => j.serviceName == _serviceFilter).toList()
        : declinedJobs;
    if (filtered.isEmpty) {
      return JobEmptyState(
        icon: Icons.block_outlined,
        title: _serviceFilter != null
            ? 'No Declined $_serviceFilter Jobs'
            : 'No Declined Jobs',
        subtitle: 'Jobs you\'ve declined will appear here.',
      );
    }
    final sorted = widget.sortJobs(filtered, widget.sort);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(incomingJobsProvider);
        ref.invalidate(incomingDeclinedJobsProvider);
        await Future.delayed(const Duration(milliseconds: 800));
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: sorted.length,
        itemBuilder: (_, i) => MyJobCard(
          job: sorted[i],
          tabType: JobTabType.incoming,
          isDeclined: true,
        ),
      ),
    );
  }

  // ── Status chips (row 1) ─────────────────────────────────────────────────

  Widget _buildStatusChips(
    List<JobModel> cleanIncoming,
    List<JobModel> declined,
  ) {
    return Container(
      color: ColorConstants.pureWhite,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _StatusChip(
              label: 'All',
              count: cleanIncoming.length,
              selected: _statusFilter == null,
              color: ColorConstants.primaryBlue,
              onTap: () => setState(() => _statusFilter = null),
            ),
            const SizedBox(width: 8),
            _StatusChip(
              label: 'New',
              count: cleanIncoming.where((j) => j.isRequested).length,
              selected: _statusFilter == 'new',
              color: ColorConstants.chipOrange,
              onTap: () => setState(() => _statusFilter = 'new'),
            ),
            const SizedBox(width: 8),
            _StatusChip(
              label: 'Quoted',
              count: cleanIncoming.where((j) => j.isQuoted).length,
              selected: _statusFilter == 'quoted',
              color: ColorConstants.chipPurple,
              onTap: () => setState(() => _statusFilter = 'quoted'),
            ),
            const SizedBox(width: 8),
            _StatusChip(
              label: 'Declined',
              count: declined.length,
              selected: _statusFilter == 'declined',
              color: ColorConstants.chipRedSoft,
              onTap: () => setState(() => _statusFilter = 'declined'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status chip widget ────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
