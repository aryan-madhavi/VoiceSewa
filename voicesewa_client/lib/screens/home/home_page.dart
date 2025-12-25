import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:voicesewa_client/screens/syncstatuspage.dart';
import 'package:voicesewa_client/widgets/home/quick_actions.dart';
import 'package:voicesewa_client/screens/home/sync_button.dart';

import 'package:voicesewa_client/database/user_app_database.dart';
import 'package:voicesewa_client/database/tables/service_request_table.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final clientIdCounterProvider = StateProvider<int>((ref) => 1);

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  Future<void> _insertTempServiceRequest(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      final db = await ClientDatabase.instance.database;
      final srTable = ServiceRequestTable(db);

      final now = DateTime.now();
      final id = 'sr_${now.millisecondsSinceEpoch}';

      // read counter
      final count = ref.read(clientIdCounterProvider);

      // increment for next click
      ref.read(clientIdCounterProvider.notifier).state++;

      final req = ServiceRequest(
        serviceRequestId: id,
        clientId: 'client_$count',
        workerId: null,
        category: 'Cleaning',
        title: 'Test request ${now.toIso8601String()}',
        description: 'Temporary seeded row from HomePage button',
        location: 'Mumbai',
        scheduledAt: now.add(const Duration(days: 1)).millisecondsSinceEpoch,
        createdAt: null,
        updatedAt: null,
        status: ServiceStatus.pending,
      );

      await srTable.upsert(req);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Inserted ServiceRequest for client_$count'),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Insert failed: $e'),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VoiceSewa'),
        actions: const [
          SyncButton(), // Add sync button to app bar
          SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [QuickActions()],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Debug button - FIXED: Changed to small FAB with unique heroTag
          FloatingActionButton.small(
            heroTag: 'debug_btn',
            onPressed: () {
              Navigator.pushNamed(context, '/sync-debug');
            },
            tooltip: 'Debug Sync',
            child: const Icon(Icons.bug_report, size: 20),
          ),
          const SizedBox(height: 12),
          // Seed button
          FloatingActionButton(
            heroTag: 'seed_btn',
            onPressed: () => _insertTempServiceRequest(context, ref),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [Icon(Icons.add), SizedBox(width: 6), Text("Seed")],
            ),
          ),
          const SizedBox(height: 16),
          // Sync FAB (alternative large sync button)
          const SyncFAB(),
        ],
      ),
    );
  }
}