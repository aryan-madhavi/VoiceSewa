import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:voicesewa_client/core/constants/color_constants.dart';
import 'package:voicesewa_client/features/jobs/presentation/create_job_screen.dart';
import 'package:voicesewa_client/shared/models/job_model.dart';
import 'package:voicesewa_client/features/jobs/providers/job_provider.dart';
import 'package:voicesewa_client/features/jobs/presentation/job_details_screen.dart';
import 'package:voicesewa_client/core/extensions/context_extensions.dart';

// ==================== STATE PROVIDERS FOR FILTER & SORT ====================

final activeStatusProvider = StateProvider<String>((ref) => 'All');
final activeSortProvider = StateProvider<String>((ref) => 'newest');

final completedStatusProvider = StateProvider<String>((ref) => 'All');
final completedSortProvider = StateProvider<String>((ref) => 'newest');

// ==================== HELPER: Translate job status key → localized string ====================

String localizedJobStatus(BuildContext context, String statusKey) {
  switch (statusKey.toLowerCase()) {
    case 'scheduled':
      return context.loc.scheduled;
    case 'inprogress':
    case 'in_progress':
      return context.loc.inProgress;
    case 'completed':
      return context.loc.completed;
    case 'cancelled':
      return context.loc.cancelled;
    case 'requested':
      return context.loc.requested;
    case 'quoted':
      return context.loc.quoted;
    case 'rescheduled':
      return context.loc.rescheduled;
    default:
      return statusKey;
  }
}

// ==================== MY REQUESTS PAGE ====================

class MyRequestsPage extends ConsumerStatefulWidget {
  const MyRequestsPage({super.key});

  @override
  ConsumerState<MyRequestsPage> createState() => _MyRequestsPageState();
}

class _MyRequestsPageState extends ConsumerState<MyRequestsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ✅ Filter uses neutral keys — compare job.statusLabel (raw English key) to statusKey
  List<Job> _applyFilter(List<Job> jobs, String statusKey, String sortKey) {
    List<Job> filteredJobs = List.from(jobs);

    // 'All' is the neutral key — skip filtering
    if (statusKey != 'All') {
      filteredJobs = filteredJobs.where((job) {
        return job.statusLabel.toLowerCase() == statusKey.toLowerCase();
      }).toList();
    }

    filteredJobs.sort((a, b) {
      switch (sortKey) {
        case 'oldest':
          return a.createdAt.compareTo(b.createdAt);
        case 'newest':
        default:
          return b.createdAt.compareTo(a.createdAt);
      }
    });

    return filteredJobs;
  }

  Widget _buildJobList(List<Job> jobs) {
    if (jobs.isEmpty) {
      return Center(child: Text(context.loc.noJobsMatchTheSelectedFilters2));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        return _JobCard(job: jobs[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final jobsAsync = ref.watch(currentUserJobsProvider);
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: ColorConstants.scaffold,
      appBar: canPop
          ? AppBar(
              title: Text(context.loc.myRequests),
              backgroundColor: ColorConstants.appBar,
            )
          : null,
      body: jobsAsync.when(
        data: (allJobs) {
          final activeJobs = allJobs.where((job) {
            return job.status == JobStatus.requested ||
                job.status == JobStatus.quoted ||
                job.status == JobStatus.scheduled ||
                job.status == JobStatus.inProgress ||
                job.status == JobStatus.rescheduled;
          }).toList();

          final completedJobs = allJobs.where((job) {
            return job.status == JobStatus.completed ||
                job.status == JobStatus.cancelled;
          }).toList();

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.black87,
                    indicatorColor: Colors.black87,
                    tabs: [
                      Tab(text: context.loc.activeJobs),
                      Tab(text: context.loc.completedJobs),
                    ],
                  ),
                ),

                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // ========== ACTIVE JOBS TAB ==========
                      Consumer(
                        builder: (context, ref, _) {
                          final statusKey = ref.watch(activeStatusProvider);
                          final sortKey = ref.watch(activeSortProvider);

                          final filteredJobs = _applyFilter(
                            activeJobs,
                            statusKey,
                            sortKey,
                          );

                          // Keys are neutral English keys used for filter logic
                          // Values are localized display strings
                          final activeStatusMap = {
                            'All': context.loc.all,
                            'Scheduled': context.loc.scheduled,
                            'inProgress': context.loc.inProgress,
                          };

                          final sortMap = {
                            'newest': context.loc.newestFirst,
                            'oldest': context.loc.oldestFirst,
                          };

                          return Column(
                            children: [
                              _DynamicJobFilterBar(
                                statusOptions: activeStatusMap,
                                sortOptions: sortMap,
                                statusProvider: activeStatusProvider,
                                sortProvider: activeSortProvider,
                              ),
                              Expanded(child: _buildJobList(filteredJobs)),
                            ],
                          );
                        },
                      ),

                      // ========== COMPLETED JOBS TAB ==========
                      Consumer(
                        builder: (context, ref, _) {
                          final statusKey = ref.watch(completedStatusProvider);
                          final sortKey = ref.watch(completedSortProvider);

                          final filteredJobs = _applyFilter(
                            completedJobs,
                            statusKey,
                            sortKey,
                          );

                          final completedStatusMap = {
                            'All': context.loc.all,
                            'Completed': context.loc.completed,
                            'Cancelled': context.loc.cancelled,
                          };

                          final sortMap = {
                            'newest': context.loc.newestFirst,
                            'oldest': context.loc.oldestFirst,
                          };

                          return Column(
                            children: [
                              _DynamicJobFilterBar(
                                statusOptions: completedStatusMap,
                                sortOptions: sortMap,
                                statusProvider: completedStatusProvider,
                                sortProvider: completedSortProvider,
                              ),
                              Expanded(child: _buildJobList(filteredJobs)),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

// ==================== DYNAMIC JOB FILTER BAR ====================

class _DynamicJobFilterBar extends ConsumerWidget {
  final Map<String, String> statusOptions;
  final Map<String, String> sortOptions;
  final StateProvider<String> statusProvider;
  final StateProvider<String> sortProvider;

  const _DynamicJobFilterBar({
    required this.statusOptions,
    required this.sortOptions,
    required this.statusProvider,
    required this.sortProvider,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedStatus = ref.watch(statusProvider);
    final selectedSort = ref.watch(sortProvider);

    // Guard: if current value not in map keys (e.g. after locale change), fall back to first key
    final safeStatus = statusOptions.containsKey(selectedStatus)
        ? selectedStatus
        : statusOptions.keys.first;
    final safeSort = sortOptions.containsKey(selectedSort)
        ? selectedSort
        : sortOptions.keys.first;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            // Status Dropdown
            Expanded(
              child: DropdownButtonFormField<String>(
                value: safeStatus,
                decoration: InputDecoration(
                  labelText: context.loc.status,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: const OutlineInputBorder(),
                ),
                items: statusOptions.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key, // neutral key — never translated
                    child: Text(
                      entry.value, // localized display label
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    ref.read(statusProvider.notifier).state = value;
                  }
                },
              ),
            ),
            const SizedBox(width: 12),

            // Sort Dropdown
            Expanded(
              child: DropdownButtonFormField<String>(
                value: safeSort,
                decoration: InputDecoration(
                  labelText: context.loc.sort,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: const OutlineInputBorder(),
                ),
                items: sortOptions.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key, // neutral key
                    child: Text(
                      entry.value, // localized display label
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    ref.read(sortProvider.notifier).state = value;
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== JOB CARD ====================

class _JobCard extends StatelessWidget {
  final Job job;

  const _JobCard({required this.job});

  bool get _shouldShowRating {
    return job.isScheduled || job.isInProgress || job.isCompleted;
  }

  bool get _shouldShowAmount {
    return job.finalizedQuotationAmount != null;
  }

  String get _displayAmount {
    if (_shouldShowAmount) {
      return job.finalizedQuotationAmount!.toStringAsFixed(0);
    }
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    Color color = job.statusColor;

    // ✅ Translate the status label for display — filter logic still uses raw job.statusLabel
    final translatedStatus = localizedJobStatus(context, job.statusLabel);

    return Card(
      margin: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => JobDetailsScreen(jobId: job.id)),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                        Icon(
                          job.serviceIcon,
                          color: job.serviceColor,
                          size: 16,
                        ),
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
                  // ✅ Pass translated status string to badge
                  _StatusBadge(status: translatedStatus, color: color),
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
                            job.workerName ?? context.loc.workerNotAssigned,
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

              // Rating and amount
              if (_shouldShowRating)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '${context.loc.yourRating}: —',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '₹$_displayAmount',
                      style: TextStyle(
                        color: _shouldShowAmount ? Colors.green : Colors.grey,
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
                    // Book Again - Only for completed/cancelled
                    if (job.isCompleted || job.isCancelled)
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
                        label: Text(
                          context.loc.bookAgain,
                          style: const TextStyle(fontSize: 13),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: ColorConstants.seed,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          minimumSize: const Size(0, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),

                    // Details - Always visible
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
                      label: Text(
                        context.loc.details,
                        style: const TextStyle(fontSize: 13),
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
      ),
    );
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
