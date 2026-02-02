import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:voicesewa_client/core/constants/color_constants.dart';
import 'package:voicesewa_client/features/jobs/presentation/create_job_screen.dart';
import 'package:voicesewa_client/shared/models/job_model.dart';
import 'package:voicesewa_client/features/jobs/providers/job_provider.dart';
import 'package:voicesewa_client/features/jobs/presentation/job_details_screen.dart';

// ==================== STATE PROVIDERS FOR FILTER & SORT ====================

final activeStatusProvider = StateProvider<String>((ref) => 'All');
final activeSortProvider = StateProvider<String>((ref) => 'newest');

final completedStatusProvider = StateProvider<String>((ref) => 'All');
final completedSortProvider = StateProvider<String>((ref) => 'newest');

// ==================== MY REQUESTS PAGE ====================

class MyRequestsPage extends ConsumerStatefulWidget {
  const MyRequestsPage({super.key});

  @override
  ConsumerState<MyRequestsPage> createState() => _MyRequestsPageState();
}

class _MyRequestsPageState extends ConsumerState<MyRequestsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  int _visibleCount = 0;
  bool _isLoadingMore = false;
  bool _initialLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_onScroll);
    _loadInitialJobs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadInitialJobs() async {
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) {
      setState(() {
        _visibleCount = 4;
        _initialLoading = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        !_initialLoading) {
      _loadMore();
    }
  }

  void _loadMore() async {
    setState(() => _isLoadingMore = true);
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      setState(() {
        _visibleCount += 4;
        _isLoadingMore = false;
      });
    }
  }

  List<Job> _applyFilter(List<Job> jobs, String statusKey, String sortKey) {
    List<Job> filteredJobs = List.from(jobs);

    // Apply status filter
    if (statusKey != 'All') {
      filteredJobs = filteredJobs.where((job) {
        return job.statusLabel.toLowerCase() == statusKey.toLowerCase();
      }).toList();
    }

    // Apply sort
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

  Widget _buildLazyJobList(List<Job> jobs) {
    if (_initialLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
    }
    if (jobs.isEmpty) {
      return const Center(child: Text('No jobs match the selected filters'));
    }

    final visibleJobs = jobs.take(_visibleCount).toList();

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: visibleJobs.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == visibleJobs.length) {
          return const Padding(
            padding: EdgeInsets.all(12.0),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        return _JobCard(job: visibleJobs[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final jobsAsync = ref.watch(currentUserJobsProvider);
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: ColorConstants.scaffold,
      appBar: canPop ? AppBar(
        title: const Text('My Requests'),
        backgroundColor: ColorConstants.appBar,
      ): null,
      body: jobsAsync.when(
        data: (allJobs) {
          // Separate active and completed jobs
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
                // Tab Bar Card
                Card(
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.black87,
                    indicatorColor: Colors.black87,
                    tabs: const [
                      Tab(text: 'Active Jobs'),
                      Tab(text: 'Completed Jobs'),
                    ],
                  ),
                ),

                // Tab Views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Active Jobs Tab
                      Consumer(
                        builder: (context, ref, _) {
                          final statusKey = ref.watch(activeStatusProvider);
                          final sortKey = ref.watch(activeSortProvider);

                          final filteredJobs = _applyFilter(
                            activeJobs,
                            statusKey,
                            sortKey,
                          );

                          final activeStatusMap = {
                            'All': 'All',
                            'Scheduled': 'Scheduled',
                            'In Progress': 'In Progress',
                          };

                          final sortMap = {
                            'newest': 'Newest First',
                            'oldest': 'Oldest First',
                          };

                          return Column(
                            children: [
                              _DynamicJobFilterBar(
                                statusOptions: activeStatusMap,
                                sortOptions: sortMap,
                                statusProvider: activeStatusProvider,
                                sortProvider: activeSortProvider,
                              ),
                              Expanded(child: _buildLazyJobList(filteredJobs)),
                            ],
                          );
                        },
                      ),

                      // Completed Jobs Tab
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
                            'All': 'All',
                            'Completed': 'Completed',
                            'Cancelled': 'Cancelled',
                          };

                          final sortMap = {
                            'newest': 'Newest First',
                            'oldest': 'Oldest First',
                          };

                          return Column(
                            children: [
                              _DynamicJobFilterBar(
                                statusOptions: completedStatusMap,
                                sortOptions: sortMap,
                                statusProvider: completedStatusProvider,
                                sortProvider: completedSortProvider,
                              ),
                              Expanded(child: _buildLazyJobList(filteredJobs)),
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

// ==================== DYNAMIC FILTER BAR ====================

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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              value: statusOptions.containsKey(selectedStatus)
                  ? selectedStatus
                  : statusOptions.keys.first,
              icon: const Icon(Icons.filter_alt_outlined, size: 20),
              decoration: InputDecoration(
                labelText: 'Filter',
                labelStyle: const TextStyle(fontSize: 13),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: statusOptions.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(entry.value, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  ref.read(statusProvider.notifier).state = value;
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              value: sortOptions.containsKey(selectedSort)
                  ? selectedSort
                  : sortOptions.keys.first,
              icon: const Icon(Icons.sort_outlined, size: 20),
              decoration: InputDecoration(
                labelText: 'Sort',
                labelStyle: const TextStyle(fontSize: 13),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: sortOptions.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(entry.value, overflow: TextOverflow.ellipsis),
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
    );
  }
}

// ==================== JOB CARD (MATCHING job_card.dart DESIGN) ====================

class _JobCard extends StatelessWidget {
  final Job job;

  const _JobCard({required this.job});

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
