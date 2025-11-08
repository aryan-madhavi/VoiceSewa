import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/widgets/history/job_card.dart';

// Active Jobs — Scheduled or In Progress
final activeJobsProvider = Provider<List<Map<String, dynamic>>>(
  (ref) => [
    {
      'service': 'Plumbing Repair',
      'description': 'Fixing kitchen sink leakage',
      'worker': 'Rajesh K.',
      'rating': '4.7',
      'date': 'Nov 5, 2025',
      'amount': '₹450',
      'status': 'In Progress',
      'userRating': '-',
    },
    {
      'service': 'Home Cleaning',
      'description': 'Full 2BHK deep cleaning service',
      'worker': 'Anita S.',
      'rating': '4.8',
      'date': 'Nov 7, 2025',
      'amount': '₹1200',
      'status': 'Scheduled',
      'userRating': '-',
    },
    {
      'service': 'AC Installation',
      'description': 'Split AC setup and testing',
      'worker': 'Vivek T.',
      'rating': '4.6',
      'date': 'Nov 9, 2025',
      'amount': '₹1500',
      'status': 'In Progress',
      'userRating': '-',
    },
    {
      'service': 'Pest Control',
      'description': 'Cockroach and ant treatment for 3BHK',
      'worker': 'Deepa R.',
      'rating': '4.9',
      'date': 'Nov 10, 2025',
      'amount': '₹800',
      'status': 'Scheduled',
      'userRating': '-',
    },
    {
      'service': 'Carpet Cleaning',
      'description': 'Dry wash and shampooing of carpets',
      'worker': 'Arun P.',
      'rating': '4.5',
      'date': 'Nov 11, 2025',
      'amount': '₹1000',
      'status': 'Scheduled',
      'userRating': '-',
    },
    {
      'service': 'Refrigerator Repair',
      'description': 'Cooling issue inspection and fix',
      'worker': 'Sanjay L.',
      'rating': '4.8',
      'date': 'Nov 8, 2025',
      'amount': '₹700',
      'status': 'In Progress',
      'userRating': '-',
    },
  ],
);

// Completed / Cancelled Jobs
final completedJobsProvider = Provider<List<Map<String, dynamic>>>(
  (ref) => [
    {
      'service': 'Wall Painting',
      'description': 'Living room painting',
      'worker': 'Ajay Singh',
      'rating': '4.9',
      'date': 'Nov 28, 2024',
      'amount': '₹2500',
      'status': 'Completed',
      'userRating': '5/5',
    },
    {
      'service': 'Car Wash',
      'description': 'Exterior and interior cleaning',
      'worker': 'Vikas G.',
      'rating': '4.8',
      'date': 'Nov 3, 2025',
      'amount': '₹600',
      'status': 'Completed',
      'userRating': '4.9/5',
    },
    {
      'service': 'Gardening',
      'description': 'Lawn trimming and plant maintenance',
      'worker': 'Rohit M.',
      'rating': '4.7',
      'date': 'Nov 1, 2025',
      'amount': '₹800',
      'status': 'Completed',
      'userRating': '4.8/5',
    },
    {
      'service': 'Furniture Assembly',
      'description': 'Bed and wardrobe installation',
      'worker': 'Nikhil D.',
      'rating': '4.6',
      'date': 'Oct 30, 2025',
      'amount': '₹500',
      'status': 'Completed',
      'userRating': '4.7/5',
    },
    {
      'service': 'AC Maintenance',
      'description': 'Filter cleaning and gas refill',
      'worker': 'Kumar P.',
      'rating': '4.9',
      'date': 'Oct 22, 2025',
      'amount': '₹900',
      'status': 'Completed',
      'userRating': '5/5',
    },
    {
      'service': 'Electrician Visit',
      'description': 'Fan wiring and socket repair',
      'worker': 'Sunil T.',
      'rating': '4.4',
      'date': 'Oct 10, 2025',
      'amount': '₹650',
      'status': 'Cancelled',
      'userRating': '-',
    },
  ],
);

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

    // Simulate initial loading delay
    _loadInitialJobs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadInitialJobs() async {
    await Future.delayed(const Duration(milliseconds: 700)); // simulate loading
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
    await Future.delayed(const Duration(milliseconds: 400)); // simulate delay
    setState(() {
      _visibleCount += 4;
      _isLoadingMore = false;
    });
  }

  Widget _buildLazyJobList(List<Map<String, dynamic>> jobs) {
    if (_initialLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
    }

    if (jobs.isEmpty) {
      return const Center(child: Text("No jobs available."));
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Tab Bar ---
            Card(
              margin: const EdgeInsets.all(8),
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

            // --- Tab Views ---
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLazyJobList(activeJobs),
                  _buildLazyJobList(completedJobs),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
