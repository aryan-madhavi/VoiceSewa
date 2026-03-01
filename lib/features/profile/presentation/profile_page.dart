import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_worker/core/constants/color_constants.dart';
import 'package:voicesewa_worker/core/extensions/context_extensions.dart';
import 'package:voicesewa_worker/core/providers/session_provider.dart'; // currentUserProvider
import 'package:voicesewa_worker/features/profile/presentation/settings_page.dart';
import 'package:voicesewa_worker/features/profile/presentation/support_and_help_page.dart';
import 'package:voicesewa_worker/features/profile/presentation/work_history_page.dart';
import 'package:voicesewa_worker/features/profile/providers/worker_profile_provider.dart';
import 'package:voicesewa_worker/features/profile/presentation/worker_profile_form_page.dart';
import 'package:voicesewa_worker/shared/models/worker_model.dart';
import 'package:voicesewa_worker/core/constants/helper_function.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUserProvider)?.uid ?? '';
    final profileAsync = ref.watch(workerProfileStreamProvider(uid));

    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.loc.myProfile,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WorkerProfileFormPage()),
            ),
            icon: const Icon(Icons.edit_note_rounded, color: Colors.black),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (worker) {
          if (worker == null) {
            return Center(child: Text(context.loc.noProfileFound));
          }
          return _ProfileBody(worker: worker);
        },
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  final WorkerModel worker;
  const _ProfileBody({required this.worker});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          const SizedBox(height: 10),
          _buildProfileHeader(context, worker),
          const SizedBox(height: 30),
          _buildStatsRow(context, worker),
          const SizedBox(height: 20),
          if (worker.skills.isNotEmpty) ...[
            _buildSkillsSection(context, worker),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              context.loc.general,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 15),
          profilePageBuildMenuCard(
            icon: Icons.settings,
            title: context.loc.settings,
            subtitle: context.loc.privacyNotificationsLanguage,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
          ),
          profilePageBuildMenuCard(
            icon: Icons.history,
            title: context.loc.workHistory,
            subtitle: context.loc.viewPastJobsAndEarnings,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WorkHistoryPage()),
            ),
          ),
          profilePageBuildMenuCard(
            icon: Icons.help_outline,
            title: context.loc.helpAndSupport,
            subtitle: context.loc.fAQsContactUs,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SupportPage()),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, WorkerModel worker) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundImage:
                    worker.profileImg != null && worker.profileImg!.isNotEmpty
                    ? NetworkImage(worker.profileImg!)
                    : const NetworkImage('https://i.pravatar.cc/300'),
                backgroundColor: Colors.grey[200],
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const WorkerProfileFormPage(),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Text(
          worker.name.isNotEmpty ? worker.name : 'No name set',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Text(
          worker.phone.isNotEmpty ? worker.phone : 'No phone set',
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        if (worker.bio != null && worker.bio!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            worker.bio!,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (worker.address?.city.isNotEmpty == true) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 14,
                color: Colors.grey,
              ),
              const SizedBox(width: 2),
              Text(
                '${worker.address!.city}${worker.address!.pincode.isNotEmpty ? ', ${worker.address!.pincode}' : ''}',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context, WorkerModel worker) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(
            worker.jobs.completed.length.toString(),
            context.loc.completed,
            Icons.check_circle_outline,
            Colors.green,
          ),
          _divider(),
          _statItem(
            worker.avgRating.toStringAsFixed(1),
            context.loc.rating,
            Icons.star_outline,
            Colors.amber,
          ),
          _divider(),
          _statItem(
            worker.jobs.confirmed.length.toString(),
            context.loc.ongoing,
            Icons.work_outline,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _divider() => Container(height: 40, width: 1, color: Colors.grey[200]);

  Widget _buildSkillsSection(BuildContext context, WorkerModel worker) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Skills',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: worker.skills
                .map(
                  (skill) => Chip(
                    label: Text(skill, style: const TextStyle(fontSize: 12)),
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
