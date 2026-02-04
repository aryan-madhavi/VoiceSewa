import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_worker/core/constants/helper_function.dart';
import 'package:voicesewa_worker/features/sync/presentation/sync_debug_page.dart';
import 'package:voicesewa_worker/features/sync/providers/sync_providers.dart';
import 'settings_section_header.dart';
import 'sync_status_card.dart';

class SyncSection extends ConsumerWidget {
  final String userId;

  const SyncSection({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatusAsync = ref.watch(syncStatusProvider(userId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: 'Data Sync'),
        const SizedBox(height: 10),

        // Sync Status Card
        syncStatusAsync.when(
          data: (status) {
            final pendingCount = status['pending'] ?? 0;
            final failedCount = status['failed'] ?? 0;
            return SyncStatusCard(
              userId: userId,
              pendingCount: pendingCount,
              failedCount: failedCount,
            );
          },
          loading: () => const SyncStatusCard(
            userId: '',
            pendingCount: 0,
            failedCount: 0,
            isLoading: true,
          ),
          error: (_, __) => const SyncStatusCard(
            userId: '',
            pendingCount: 0,
            failedCount: 0,
            hasError: true,
          ),
        ),

        const SizedBox(height: 10),

        // Sync Debug Button
        settingsPageBuildActionTile(
          'Sync Debug',
          Icons.bug_report,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SyncDebugPage()),
          ),
        ),
      ],
    );
  }
}
