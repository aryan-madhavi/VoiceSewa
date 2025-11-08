import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/widgets/history/job_card.dart';

final activeJobsProvider = Provider<List<Map<String, dynamic>>>((ref) => [
  {
    'service': 'Plumbing Repair',
    'date': 'Nov 5, 2025',
    'amount': '₹450',
    'status': 'In Progress',
    'worker': 'Rajesh K.',
    'eta': '30 mins',
  },
  {
    'service': 'Home Cleaning',
    'date': 'Nov 7, 2025',
    'amount': '₹1200',
    'status': 'Scheduled',
    'worker': 'Anita S.',
    'eta': 'Tomorrow, 10 AM',
  },
]);

final completedJobsProvider = Provider<List<Map<String, dynamic>>>((ref) => [
  {
    'service': 'AC Maintenance',
    'date': 'Oct 22, 2025',
    'amount': '₹900',
    'status': 'Completed',
    'worker': 'Kumar P.',
    'eta': 'Completed on Oct 22',
  },
  {
    'service': 'Electrician Visit',
    'date': 'Oct 10, 2025',
    'amount': '₹650',
    'status': 'Cancelled',
    'worker': 'Sunil T.',
    'eta': 'Cancelled',
  },
]);

class RequestPage extends ConsumerStatefulWidget {
  const RequestPage({super.key});

  @override
  ConsumerState<RequestPage> createState() => _RequestPageState();
}

class _RequestPageState extends ConsumerState<RequestPage>
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

  Widget _buildJobList(List<Map<String, dynamic>> jobs) {
    if (jobs.isEmpty) {
      return const Center(child: Text("No jobs available."));
    }
    return Column(
      children: jobs.map((job) => JobCard(job: job)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeJobs = ref.watch(activeJobsProvider);
    final completedJobs = ref.watch(completedJobsProvider);

    return Scaffold(
      body: SingleChildScrollView(
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
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Active Jobs'),
                    Tab(text: 'Completed Jobs'),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                height: MediaQuery.of(context).size.height * 0.75,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    SingleChildScrollView(child: _buildJobList(activeJobs)),
                    SingleChildScrollView(child: _buildJobList(completedJobs)),
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
