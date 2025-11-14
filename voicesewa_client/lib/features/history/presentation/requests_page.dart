import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/features/history/providers/booking_data_provider.dart';
import 'package:voicesewa_client/features/history/providers/booking_filter_provider.dart';
import 'package:voicesewa_client/features/history/model/booking_model.dart';
import 'package:voicesewa_client/features/history/presentation/widgets/dynamic_job_filter.dart';
import 'package:voicesewa_client/features/history/presentation/widgets/job_card.dart';

class RequestPage extends ConsumerStatefulWidget {
  const RequestPage({super.key});

  @override
  ConsumerState<RequestPage> createState() => _RequestPageState();
}

class _RequestPageState extends ConsumerState<RequestPage>
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
    setState(() {
      _visibleCount = 4;
      _initialLoading = false;
    });
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
    setState(() {
      _visibleCount += 4;
      _isLoadingMore = false;
    });
  }

  List<BookingModel> _applyFilter(
    List<BookingModel> jobs,
    String status,
    String sortOption,
  ) {
    // ✅ Step 1: Apply status filter
    List<BookingModel> filteredJobs = List.from(jobs);
    if (status.toLowerCase() != 'all') {
      filteredJobs = filteredJobs
          .where((job) => job.status.toLowerCase() == status.toLowerCase())
          .toList();
    }

    // ✅ Step 2: Apply sorting logic
    filteredJobs.sort((a, b) {
      switch (sortOption) {
        case 'Oldest First':
          return a.date.compareTo(b.date);

        case 'Amount ↑':
          return a.amount.compareTo(b.amount);

        case 'Amount ↓':
          return b.amount.compareTo(a.amount);

        case 'Rating ↑':
          return a.workerRating.compareTo(b.workerRating);

        case 'Rating ↓':
          return b.workerRating.compareTo(a.workerRating);

        default: // 'Newest First'
          return b.date.compareTo(a.date);
      }
    });

    return filteredJobs;
  }

  Widget _buildLazyJobList(List<BookingModel> jobs) {
  if (_initialLoading) {
    return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
  }

  if (jobs.isEmpty) {
    return const Center(child: Text("No jobs match the selected filters."));
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
      return JobCard(job: visibleJobs[index]);
    },
  );
}


  @override
  Widget build(BuildContext context) {
    final activeJobs = ref.watch(activeJobsProvider);
    final completedJobs = ref.watch(completedJobsProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // --- Active Jobs ---
                  Consumer(
                    builder: (context, ref, _) {
                      final status = ref.watch(activeStatusProvider);
                      final sort = ref.watch(activeSortProvider);
                      final filteredJobs = _applyFilter(
                        activeJobs,
                        status,
                        sort,
                      );
      
                      return Column(
                        children: [
                          DynamicJobFilterBar(
                            statusOptions: [
                              'All',
                              'Scheduled',
                              'In Progress',
                            ],
                            sortOptions: [
                              'Newest First',
                              'Oldest First',
                              'Amount ↑',
                              'Amount ↓',
                              'Rating ↑',
                              'Rating ↓',
                            ],
                            statusProvider: activeStatusProvider,
                            sortProvider: activeSortProvider,
                          ),
                          Expanded(child: _buildLazyJobList(filteredJobs)),
                        ],
                      );
                    },
                  ),
      
                  // --- Completed Jobs ---
                  Consumer(
                    builder: (context, ref, _) {
                      final status = ref.watch(completedStatusProvider);
                      final sort = ref.watch(completedSortProvider);
                      final filteredJobs = _applyFilter(
                        completedJobs,
                        status,
                        sort,
                      );
      
                      return Column(
                        children: [
                          DynamicJobFilterBar(
                            statusOptions: ['All', 'Completed', 'Cancelled'],
                            sortOptions: [
                              'Newest First',
                              'Oldest First',
                              'Amount ↑',
                              'Amount ↓',
                              'Rating ↑',
                              'Rating ↓',
                            ],
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
      ),
    );
  }
}
