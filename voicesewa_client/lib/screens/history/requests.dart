import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/constants/core/helper_functions.dart';
import 'package:voicesewa_client/providers/job_filter_provider.dart';
import 'package:voicesewa_client/widgets/history/dynamic_job_filter.dart';
import 'package:voicesewa_client/widgets/history/job_card.dart';

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

  List<Map<String, dynamic>> _applyFilter(
      List<Map<String, dynamic>> jobs, String status, String sortOption) {
    List<Map<String, dynamic>> filteredJobs = List.from(jobs);

    if (status != 'All') {
      filteredJobs = filteredJobs.where((job) => job['status'] == status).toList();
    }

    int _parseAmount(String amount) =>
        int.parse(amount.replaceAll('₹', '').replaceAll(',', ''));

    filteredJobs.sort((a, b) {
      switch (sortOption) {
        case 'Oldest First':
          return Helpers.parseDate(a['date']).compareTo(Helpers.parseDate(b['date']));
        case 'Amount ↑':
          return _parseAmount(a['amount']).compareTo(_parseAmount(b['amount']));
        case 'Amount ↓':
          return _parseAmount(b['amount']).compareTo(_parseAmount(a['amount']));
        case 'Rating ↑':
          return double.parse(a['rating']).compareTo(double.parse(b['rating']));
        case 'Rating ↓':
          return double.parse(b['rating']).compareTo(double.parse(a['rating']));
        default: // Newest First
          return Helpers.parseDate(b['date']).compareTo(Helpers.parseDate(a['date']));
      }
    });

    return filteredJobs;
  }

  Widget _buildLazyJobList(List<Map<String, dynamic>> jobs) {
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
      body: SafeArea(
        child: Padding(
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
                        final filteredJobs = _applyFilter(activeJobs, status, sort);

                        return Column(
                          children: [
                            DynamicJobFilterBar(
                              statusOptions: ['All', 'Scheduled', 'In Progress'],
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
                        final filteredJobs =
                            _applyFilter(completedJobs, status, sort);

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
      ),
    );
  }
}
