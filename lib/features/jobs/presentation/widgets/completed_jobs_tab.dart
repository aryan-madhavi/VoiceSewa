import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_worker/core/constants/color_constants.dart';
import 'package:voicesewa_worker/features/jobs/providers/job_provider.dart';
import 'package:voicesewa_worker/features/jobs/presentation/widgets/my_job_card.dart';
import 'package:voicesewa_worker/features/profile/providers/worker_profile_provider.dart';
import 'package:voicesewa_worker/shared/models/job_model.dart';
import 'job_filter_bar.dart';
import 'job_empty_state.dart';
import 'service_filter_row.dart';

class CompletedJobsTab extends ConsumerStatefulWidget {
  final String sort;
  final ValueChanged<String> onSortChanged;
  final List<JobModel> Function(List<JobModel>, String) sortJobs;
  final List<String> sortOptions;

  const CompletedJobsTab({
    super.key,
    required this.sort,
    required this.onSortChanged,
    required this.sortJobs,
    required this.sortOptions,
  });

  @override
  ConsumerState<CompletedJobsTab> createState() => _CompletedJobsTabState();
}

class _CompletedJobsTabState extends ConsumerState<CompletedJobsTab> {
  // ── View state ────────────────────────────────────────────────────────────
  String? _statusFilter; // null = completed view, 'withdrawn' = withdrawn view
  String? _serviceFilter;

  // ── Lazy load state ───────────────────────────────────────────────────────
  final List<JobModel> _extraPages = [];
  bool _loadingMore = false;
  bool _hasMore = true;

  int _lastStreamPageSize = 0;

  // ─────────────────────────────────────────────────────────────────────────

  List<JobModel> _mergeCompleted(List<JobModel> streamPage) {
    if (streamPage.length > _lastStreamPageSize) {
      _extraPages.clear();
      _hasMore = true;
    }
    _lastStreamPageSize = streamPage.length;

    final seen = <String>{};
    final merged = <JobModel>[];
    for (final j in [...streamPage, ..._extraPages]) {
      if (seen.add(j.jobId)) merged.add(j);
    }
    return merged;
  }

  Future<void> _loadMore(int currentlyShowing) async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);

    final more = await ref.read(loadMoreCompletedProvider)(
      alreadyLoadedCount: currentlyShowing,
    );

    if (!mounted) return;
    setState(() {
      _loadingMore = false;
      if (more.isEmpty) {
        _hasMore = false;
      } else {
        final existingIds = _extraPages.map((j) => j.jobId).toSet();
        _extraPages.addAll(more.where((j) => !existingIds.contains(j.jobId)));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final completed = ref.watch(completedJobsProvider);
    final trueWithdrawn = ref.watch(trueWithdrawnJobsProvider);
    final uid = ref.watch(currentWorkerUidProvider);
    final profileAsync = ref.watch(workerProfileStreamProvider(uid));

    final completedJobs = completed.value ?? [];
    // Only jobs where the worker explicitly withdrew (not rejected-by-client)
    final withdrawnJobs = trueWithdrawn.value ?? [];
    final workerSkills = profileAsync.value?.skills ?? [];

    final isWithdrawnView = _statusFilter == 'withdrawn';

    return Column(
      children: [
        JobFilterBar(
          sort: widget.sort,
          onSortChanged: widget.onSortChanged,
          sortOptions: widget.sortOptions,
        ),
        _buildStatusChips(completedJobs, withdrawnJobs),
        if (!isWithdrawnView)
          ServiceFilterRow(
            skills: workerSkills,
            jobs: completedJobs,
            selectedService: _serviceFilter,
            onSelected: (s) => setState(() => _serviceFilter = s),
          ),
        const Divider(height: 1),
        Expanded(
          child: isWithdrawnView
              ? _buildWithdrawnList(trueWithdrawn)
              : _buildCompletedList(completed, completedJobs),
        ),
      ],
    );
  }

  // ── Completed list ────────────────────────────────────────────────────────

  Widget _buildCompletedList(
    AsyncValue<List<JobModel>> completedAsync,
    List<JobModel> streamPage,
  ) {
    return completedAsync.when(
      loading: () => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(completedJobsProvider);
          await Future.delayed(const Duration(milliseconds: 800));
        },
        child: ListView(
          children: [
            SizedBox(
              height: 300,
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
      error: (e, _) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(completedJobsProvider);
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
                      style: const TextStyle(color: ColorConstants.textGrey),
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
      data: (_) {
        final allJobs = _mergeCompleted(streamPage);

        final filtered = _serviceFilter != null
            ? allJobs.where((j) => j.serviceName == _serviceFilter).toList()
            : allJobs;

        if (filtered.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _extraPages.clear();
                _hasMore = true;
                _lastStreamPageSize = 0;
                _loadingMore = false;
              });
              ref.invalidate(completedJobsProvider);
              await Future.delayed(const Duration(milliseconds: 800));
            },
            child: ListView(
              children: [
                SizedBox(
                  height: 400,
                  child: JobEmptyState(
                    icon: Icons.check_circle_outline,
                    title: _serviceFilter != null
                        ? 'No Completed $_serviceFilter Jobs'
                        : 'No Completed Jobs',
                    subtitle: _serviceFilter != null
                        ? 'No completed jobs for this service yet.'
                        : 'Your job history will appear here.',
                  ),
                ),
              ],
            ),
          );
        }

        final sorted = widget.sortJobs(filtered, widget.sort);
        final showFooter = _hasMore || _loadingMore;

        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollUpdateNotification) {
              final pos = notification.metrics;
              if (pos.pixels >= pos.maxScrollExtent - 200) {
                _loadMore(allJobs.length);
              }
            }
            return false;
          },
          child: RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _extraPages.clear();
                _hasMore = true;
                _lastStreamPageSize = 0;
                _loadingMore = false;
              });
              ref.invalidate(completedJobsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: sorted.length + (showFooter ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == sorted.length) {
                  return _loadingMore
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                      : const SizedBox(height: 8);
                }
                return MyJobCard(job: sorted[i], tabType: JobTabType.completed);
              },
            ),
          ),
        );
      },
    );
  }

  // ── Withdrawn list ────────────────────────────────────────────────────────
  // trueWithdrawnJobsProvider already filters to quotation.status == withdrawn,
  // so this list only ever contains jobs the worker explicitly withdrew from.

  Widget _buildWithdrawnList(AsyncValue<List<JobModel>> withdrawn) {
    return withdrawn.when(
      loading: () => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(trueWithdrawnJobsProvider);
          await Future.delayed(const Duration(milliseconds: 800));
        },
        child: ListView(
          children: [
            SizedBox(
              height: 300,
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
      error: (e, _) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(trueWithdrawnJobsProvider);
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
                      style: const TextStyle(color: ColorConstants.textGrey),
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
        if (jobs.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(trueWithdrawnJobsProvider);
              await Future.delayed(const Duration(milliseconds: 800));
            },
            child: ListView(
              children: const [
                SizedBox(
                  height: 400,
                  child: JobEmptyState(
                    icon: Icons.undo_outlined,
                    title: 'No Withdrawn Quotations',
                    subtitle:
                        'Jobs where you withdrew your quotation will appear here.',
                  ),
                ),
              ],
            ),
          );
        }
        final sorted = widget.sortJobs(jobs, widget.sort);
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(trueWithdrawnJobsProvider);
            await Future.delayed(const Duration(milliseconds: 800));
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: sorted.length,
            itemBuilder: (_, i) => _WithdrawnJobCard(job: sorted[i]),
          ),
        );
      },
    );
  }

  // ── Status chips ──────────────────────────────────────────────────────────

  Widget _buildStatusChips(
    List<JobModel> completedJobs,
    List<JobModel> withdrawnJobs,
  ) {
    return Container(
      color: ColorConstants.pureWhite,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Row(
        children: [
          _CompletedChip(
            label: 'Completed',
            count: completedJobs.length,
            selected: _statusFilter == null,
            color: ColorConstants.successGreen,
            icon: Icons.check_circle_outline,
            onTap: () => setState(() => _statusFilter = null),
          ),
          const SizedBox(width: 8),
          _CompletedChip(
            label: 'Withdrawn',
            // Count shown is the raw stream length — the actual filtered
            // count is resolved asynchronously per card via quotation fetch.
            count: withdrawnJobs.length,
            selected: _statusFilter == 'withdrawn',
            color: ColorConstants.withdrawnGrey,
            icon: Icons.undo_outlined,
            onTap: () => setState(() {
              _statusFilter = 'withdrawn';
              _serviceFilter = null;
            }),
          ),
        ],
      ),
    );
  }
}

// ── Withdrawn job card ─────────────────────────────────────────────────────

class _WithdrawnJobCard extends StatelessWidget {
  final JobModel job;
  const _WithdrawnJobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shadowColor: ColorConstants.shadowBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: job.serviceColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          job.serviceIcon,
                          size: 18,
                          color: job.serviceColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              job.serviceName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: ColorConstants.textDark,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Job #${job.jobId.substring(0, 6).toUpperCase()}',
                              style: const TextStyle(
                                color: ColorConstants.textGrey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: ColorConstants.chipGreySurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: ColorConstants.chipGreyBorder,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.undo_outlined,
                              size: 11,
                              color: ColorConstants.withdrawnGrey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Withdrawn',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: ColorConstants.withdrawnGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: ColorConstants.textGrey,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          job.address.displayAddress.isNotEmpty
                              ? job.address.displayAddress
                              : 'Location not specified',
                          style: const TextStyle(
                            fontSize: 13,
                            color: ColorConstants.textGrey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (job.createdAt != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: ColorConstants.textGrey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          job.formattedCreatedDate,
                          style: const TextStyle(
                            fontSize: 13,
                            color: ColorConstants.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Left accent bar
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 5,
              child: Container(
                decoration: BoxDecoration(
                  color: ColorConstants.chipGreyBadge,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Completed / Withdrawn chip ────────────────────────────────────────────

class _CompletedChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _CompletedChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? color.withOpacity(0.1)
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
