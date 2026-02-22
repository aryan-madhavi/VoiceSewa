import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_worker/core/constants/color_constants.dart';
import 'package:voicesewa_worker/features/jobs/providers/job_provider.dart';
import 'package:voicesewa_worker/features/jobs/presentation/widgets/my_job_card.dart';
import 'package:voicesewa_worker/shared/models/job_model.dart';

class MyJobsPage extends ConsumerStatefulWidget {
  const MyJobsPage({super.key});

  @override
  ConsumerState<MyJobsPage> createState() => _MyJobsPageState();
}

class _MyJobsPageState extends ConsumerState<MyJobsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Filters
  String _incomingSort = 'Newest First';
  String _ongoingSort = 'Newest First';
  String _completedSort = 'Newest First';

  static const _sortOptions = ['Newest First', 'Oldest First'];

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
                _IncomingTab(
                  sort: _incomingSort,
                  onSortChanged: (v) => setState(() => _incomingSort = v),
                  sortJobs: _sortJobs,
                ),
                _OngoingTab(
                  sort: _ongoingSort,
                  onSortChanged: (v) => setState(() => _ongoingSort = v),
                  sortJobs: _sortJobs,
                ),
                _CompletedTab(
                  sort: _completedSort,
                  onSortChanged: (v) => setState(() => _completedSort = v),
                  sortJobs: _sortJobs,
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
      color: Colors.white,
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

// ── Filter Bar ─────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final String sort;
  final ValueChanged<String> onSortChanged;
  final List<String> sortOptions;

  const _FilterBar({
    required this.sort,
    required this.onSortChanged,
    required this.sortOptions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.white,
      child: Row(
        children: [
          const Icon(Icons.sort, size: 16, color: ColorConstants.textGrey),
          const SizedBox(width: 8),
          const Text(
            'Sort:',
            style: TextStyle(fontSize: 13, color: ColorConstants.textGrey),
          ),
          const SizedBox(width: 8),
          _DropdownChip(
            value: sort,
            options: sortOptions,
            onChanged: onSortChanged,
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _DropdownChip extends StatelessWidget {
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _DropdownChip({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey.shade50,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 16),
          style: const TextStyle(
            fontSize: 13,
            color: ColorConstants.textDark,
            fontWeight: FontWeight.w500,
          ),
          items: options
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ColorConstants.primaryBlue.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: ColorConstants.primaryBlue.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: ColorConstants.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: ColorConstants.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Incoming Tab ───────────────────────────────────────────────────────────

class _IncomingTab extends ConsumerWidget {
  final String sort;
  final ValueChanged<String> onSortChanged;
  final List<JobModel> Function(List<JobModel>, String) sortJobs;

  const _IncomingTab({
    required this.sort,
    required this.onSortChanged,
    required this.sortJobs,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incoming = ref.watch(incomingJobsProvider);

    return Column(
      children: [
        _FilterBar(
          sort: sort,
          onSortChanged: onSortChanged,
          sortOptions: _MyJobsPageState._sortOptions,
        ),
        const Divider(height: 1),
        Expanded(
          child: incoming.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (jobs) {
              if (jobs.isEmpty) {
                return const _EmptyState(
                  icon: Icons.inbox_outlined,
                  title: 'No Incoming Jobs',
                  subtitle: 'New jobs matching your skills\nwill appear here.',
                );
              }
              final sorted = sortJobs(jobs, sort);
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(incomingJobsProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: sorted.length,
                  itemBuilder: (_, i) =>
                      MyJobCard(job: sorted[i], tabType: JobTabType.incoming),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Ongoing Tab ────────────────────────────────────────────────────────────

class _OngoingTab extends ConsumerWidget {
  final String sort;
  final ValueChanged<String> onSortChanged;
  final List<JobModel> Function(List<JobModel>, String) sortJobs;

  const _OngoingTab({
    required this.sort,
    required this.onSortChanged,
    required this.sortJobs,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ongoing = ref.watch(ongoingJobsProvider);

    return Column(
      children: [
        _FilterBar(
          sort: sort,
          onSortChanged: onSortChanged,
          sortOptions: _MyJobsPageState._sortOptions,
        ),
        const Divider(height: 1),
        Expanded(
          child: ongoing.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (jobs) {
              if (jobs.isEmpty) {
                return const _EmptyState(
                  icon: Icons.work_outline,
                  title: 'No Active Jobs',
                  subtitle:
                      'Jobs you\'ve been confirmed for\nwill appear here.',
                );
              }
              final sorted = sortJobs(jobs, sort);
              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: sorted.length,
                itemBuilder: (_, i) =>
                    MyJobCard(job: sorted[i], tabType: JobTabType.ongoing),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Completed Tab ──────────────────────────────────────────────────────────

class _CompletedTab extends ConsumerWidget {
  final String sort;
  final ValueChanged<String> onSortChanged;
  final List<JobModel> Function(List<JobModel>, String) sortJobs;

  const _CompletedTab({
    required this.sort,
    required this.onSortChanged,
    required this.sortJobs,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completed = ref.watch(completedJobsProvider);

    return Column(
      children: [
        _FilterBar(
          sort: sort,
          onSortChanged: onSortChanged,
          sortOptions: _MyJobsPageState._sortOptions,
        ),
        const Divider(height: 1),
        Expanded(
          child: completed.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (jobs) {
              if (jobs.isEmpty) {
                return const _EmptyState(
                  icon: Icons.check_circle_outline,
                  title: 'No Completed Jobs',
                  subtitle: 'Your job history will appear here.',
                );
              }
              final sorted = sortJobs(jobs, sort);
              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: sorted.length,
                itemBuilder: (_, i) =>
                    MyJobCard(job: sorted[i], tabType: JobTabType.completed),
              );
            },
          ),
        ),
      ],
    );
  }
}
