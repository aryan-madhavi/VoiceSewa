import 'package:flutter/material.dart';
import 'package:voicesewa_worker/core/constants/color_constants.dart';
import 'package:voicesewa_worker/shared/models/job_model.dart';
import 'widgets/incoming_jobs_tab.dart';
import 'widgets/ongoing_jobs_tab.dart';
import 'widgets/completed_jobs_tab.dart';

class MyJobsPage extends StatefulWidget {
  const MyJobsPage({super.key});

  @override
  State<MyJobsPage> createState() => _MyJobsPageState();
}

class _MyJobsPageState extends State<MyJobsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String _incomingSort = 'Newest First';
  String _ongoingSort = 'Newest First';
  String _completedSort = 'Newest First';

  static const sortOptions = ['Newest First', 'Oldest First'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<JobModel> _sortJobs(List<JobModel> jobs, String sort) {
    final sorted = List<JobModel>.from(jobs);
    sorted.sort((a, b) {
      final aDate = a.createdAt ?? DateTime(0);
      final bDate = b.createdAt ?? DateTime(0);
      return sort == 'Newest First'
          ? bDate.compareTo(aDate)
          : aDate.compareTo(bDate);
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                IncomingJobsTab(
                  sort: _incomingSort,
                  onSortChanged: (v) => setState(() => _incomingSort = v),
                  sortJobs: _sortJobs,
                  sortOptions: sortOptions,
                ),
                OngoingJobsTab(
                  sort: _ongoingSort,
                  onSortChanged: (v) => setState(() => _ongoingSort = v),
                  sortJobs: _sortJobs,
                  sortOptions: sortOptions,
                ),
                CompletedJobsTab(
                  sort: _completedSort,
                  onSortChanged: (v) => setState(() => _completedSort = v),
                  sortJobs: _sortJobs,
                  sortOptions: sortOptions,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: ColorConstants.pureWhite,
      child: TabBar(
        controller: _tabController,
        labelColor: ColorConstants.primaryBlue,
        unselectedLabelColor: ColorConstants.textGrey,
        indicatorColor: ColorConstants.primaryBlue,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        tabs: const [
          Tab(text: 'Incoming'),
          Tab(text: 'Ongoing'),
          Tab(text: 'Completed'),
        ],
      ),
    );
  }
}
  