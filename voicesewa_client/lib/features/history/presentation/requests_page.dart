import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/core/extensions/context_extensions.dart';
import 'package:voicesewa_client/features/history/providers/booking_data_provider.dart';
import 'package:voicesewa_client/features/history/providers/booking_filter_provider.dart';
import 'package:voicesewa_client/shared/models/booking_model.dart';
import 'package:voicesewa_client/features/history/presentation/widgets/dynamic_job_filter.dart';
import 'package:voicesewa_client/features/history/presentation/widgets/job_card.dart';

class RequestPage extends ConsumerStatefulWidget {
  const RequestPage({super.key});
  @override
  ConsumerState<RequestPage> createState() => _RequestPageState();
}

class _RequestPageState extends ConsumerState<RequestPage> with SingleTickerProviderStateMixin {
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
    if(mounted) setState(() { _visibleCount = 4; _initialLoading = false; });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && !_isLoadingMore && !_initialLoading) {
      _loadMore();
    }
  }

  void _loadMore() async {
    setState(() => _isLoadingMore = true);
    await Future.delayed(const Duration(milliseconds: 400));
    if(mounted) setState(() { _visibleCount += 4; _isLoadingMore = false; });
  }

  List<BookingModel> _applyFilter(List<BookingModel> jobs, String statusKey, String sortKey) {

    List<BookingModel> filteredJobs = List.from(jobs);

    if (statusKey != 'All') {
      filteredJobs = filteredJobs
          .where((job) => job.status.toLowerCase() == statusKey.toLowerCase())
          .toList();
    }

    filteredJobs.sort((a, b) {
      switch (sortKey) {
        case 'oldest':
          return a.date.compareTo(b.date);
        case 'amount_asc':
          return a.amount.compareTo(b.amount);
        case 'amount_desc':
          return b.amount.compareTo(a.amount);
        case 'rating_asc':
          return a.workerRating.compareTo(b.workerRating);
        case 'rating_desc':
          return b.workerRating.compareTo(a.workerRating);
        case 'newest':
        default:
          return b.date.compareTo(a.date);
      }
    });

    return filteredJobs;
  }

  Widget _buildLazyJobList(List<BookingModel> jobs) {
    if (_initialLoading) return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
    if (jobs.isEmpty) return Center(child: Text(context.loc.noJobsMatchTheSelectedFilters));

    final visibleJobs = jobs.take(_visibleCount).toList();

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: visibleJobs.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == visibleJobs.length) {
          return const Padding(padding: EdgeInsets.all(12.0), child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
        }
        return JobCard(job: visibleJobs[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeJobs = ref.watch(activeJobsProvider);
    final completedJobs = ref.watch(completedJobsProvider);
    final Map<String, String> sortMap = {
      'newest': context.loc.newestFirst,
      'oldest': context.loc.oldestFirst,
      'amount_asc': '${context.loc.amount} ↑',
      'amount_desc': '${context.loc.amount} ↓',
      'rating_asc': '${context.loc.rating} ↑',
      'rating_desc': '${context.loc.rating} ↓',
    };

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
                  Consumer(
                    builder: (context, ref, _) {
                      final statusKey = ref.watch(activeStatusProvider);
                      final sortKey = ref.watch(activeSortProvider);

                      final filteredJobs = _applyFilter(activeJobs, statusKey, sortKey);

                      // ✅ Map for Active Statuses
                      final activeStatusMap = {
                        'All': context.loc.all,
                        'Scheduled': context.loc.scheduled,
                        'In Progress': context.loc.inProgress,
                      };

                      return Column(
                        children: [
                          DynamicJobFilterBar(
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

                  Consumer(
                    builder: (context, ref, _) {
                      final statusKey = ref.watch(completedStatusProvider);
                      final sortKey = ref.watch(completedSortProvider);

                      final filteredJobs = _applyFilter(completedJobs, statusKey, sortKey);

                      // ✅ Map for Completed Statuses
                      final completedStatusMap = {
                        'All': context.loc.all,
                        'Completed': context.loc.completed,
                        'Cancelled': context.loc.cancelled,
                      };

                      return Column(
                        children: [
                          DynamicJobFilterBar(
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
      ),
    );
  }
}
