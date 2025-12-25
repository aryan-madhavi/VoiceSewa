import 'package:flutter/material.dart';
import 'package:riverpod/legacy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/features/auth/data/tables/service_request_table.dart';
import 'package:voicesewa_client/features/auth/data/user_app_database.dart';

final clientIdCounterProvider = StateProvider<int>((ref) => 1);

Future<void> insertTempServiceRequest(
      BuildContext context, WidgetRef ref) async {
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
        description: 'Temporary seeded row from SettingsPage button',
        location: 'Mumbai',
        scheduledAt: now.add(const Duration(days: 1)).millisecondsSinceEpoch,
        createdAt: null,
        updatedAt: null,
        status: ServiceStatus.pending,
      );

      await srTable.upsert(req);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Inserted ServiceRequest for client_$count')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Insert failed: $e')),
        );
      }
    }
  }
