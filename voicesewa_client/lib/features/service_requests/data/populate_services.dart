import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:voicesewa_client/core/database/app_database.dart';
import 'package:voicesewa_client/core/database/daos/service_request_dao.dart';
import 'package:voicesewa_client/features/service_requests/domain/service_request_model.dart';
import 'package:voicesewa_client/features/sync/providers/sync_providers.dart';

final clientIdCounterProvider = StateProvider<int>((ref) => 1);

Future<void> insertTempServiceRequest(BuildContext context, WidgetRef ref) async {
  try {
    // Get database instance
    final db = await AppDatabase.instance.database;

    // Get the sync DAO from Riverpod
    final syncDao = await ref.read(pendingSyncDaoProvider.future);

    // Instantiate ServiceRequestDao
    final srDao = ServiceRequestDao(db, syncDao);

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

    await srDao.upsert(req);

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
