import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:voicesewa_worker/core/database/app_database.dart';
import 'package:voicesewa_worker/core/providers/database_provider.dart';
import 'package:voicesewa_worker/core/database/tables/worker_profile_table.dart';
import 'package:voicesewa_worker/core/database/tables/booking_table.dart';
import 'package:voicesewa_worker/core/database/dao/worker_profile_dao.dart';
import 'package:voicesewa_worker/core/database/dao/booking_dao.dart';
import 'package:voicesewa_worker/features/sync/providers/sync_providers.dart';

class SyncDebugPage extends ConsumerWidget {
  const SyncDebugPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userHasDb = ref.watch(userHasDatabaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Queue Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final userId = _getUserId();
              if (userId != null) {
                ref.invalidate(syncServiceProvider(userId));
                ref.invalidate(pendingSyncDaoProvider(userId));
              }
            },
          ),
        ],
      ),
      body: userHasDb.when(
        data: (hasDb) {
          if (!hasDb) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Database not initialized'),
                  const SizedBox(height: 8),
                  const Text('Please log out and log back in'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          return _buildSyncQueueView(ref, context);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: $err'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Populate Data Button
          FloatingActionButton.extended(
            heroTag: 'populate_btn',
            onPressed: () => _populateTestData(context, ref),
            backgroundColor: Colors.purple,
            icon: const Icon(Icons.add_circle),
            label: const Text('Populate Data'),
          ),
          const SizedBox(height: 12),
          // Force Sync Button
          FloatingActionButton.extended(
            heroTag: 'sync_btn',
            onPressed: () => _forceSyncData(context, ref),
            backgroundColor: Colors.blue,
            icon: const Icon(Icons.sync),
            label: const Text('Force Sync'),
          ),
        ],
      ),
    );
  }

  /// Helper to get current user ID
  String? _getUserId() {
    return WorkerDatabase.currentUserId ??
        FirebaseAuth.instance.currentUser?.email;
  }

  Future<void> _populateTestData(BuildContext context, WidgetRef ref) async {
    try {
      // Get userId first
      final userId = _getUserId();
      if (userId == null || userId.isEmpty) {
        throw Exception('No user logged in');
      }

      // Get database with explicit userId
      final db = await ref.read(sqfliteDatabaseProvider(userId).future);
      final uuid = const Uuid();

      // Show loading
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🔄 Populating test data...')),
        );
      }

      final now = DateTime.now().millisecondsSinceEpoch;

      // 1. Create test Worker Profile
      final workerDao = WorkerProfileDao(db);
      final workerId = userId; // Use actual userId

      final profile = WorkerProfile(
        workerId: workerId,
        name: 'Test Worker ${DateTime.now().second}',
        phone: '+91${9000000000 + DateTime.now().second}',
        language: 'English',
        skillCategory: 'Plumbing',
        bio: 'Test worker created at ${DateTime.now()}',
        updatedAt: now,
      );

      await workerDao.upsert(profile);
      print('✅ Created worker profile: $workerId');

      // Job offers are fetched from Firestore, not inserted locally

      // 2. Create test Bookings
      final bookingDao = BookingDao(db);

      for (int i = 0; i < 2; i++) {
        final bookingId = uuid.v4();
        final booking = Booking(
          bookingId: bookingId,
          jobOfferId: 'job_${uuid.v4().substring(0, 8)}',
          workerId: workerId,
          clientId: 'client_${uuid.v4().substring(0, 8)}',
          scheduledAt: now + (i * 3600000), // +1 hour each
          status: BookingStatus.values[i % 5],
          updatedAt: now,
        );

        await bookingDao.upsert(booking);
        print('✅ Created booking: $bookingId');
      }

      // Refresh the UI
      if (context.mounted) {
        ref.invalidate(pendingSyncDaoProvider(userId));

        // Get updated sync status
        final syncStatus = await ref.read(syncStatusProvider(userId).future);
        final pendingCount = syncStatus['pending'] ?? 0;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Created test data! $pendingCount items pending sync',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Error populating test data: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _forceSyncData(BuildContext context, WidgetRef ref) async {
    try {
      final userId = _getUserId();
      if (userId == null || userId.isEmpty) {
        throw Exception('No user logged in');
      }

      final syncAsync = ref.read(syncServiceProvider(userId));

      await syncAsync.whenData((syncService) async {
        if (syncService == null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ Sync service not available'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Call syncPending and get the result
        final result = await syncService.syncPending();

        if (context.mounted) {
          // Handle different result scenarios
          if (result['noInternet'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ No internet connection'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          } else if (result['skipped'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⏳ Sync already in progress'),
                backgroundColor: Colors.orange,
              ),
            );
          } else if (result['success'] == true) {
            final synced = result['synced'] ?? 0;
            if (synced > 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ Successfully synced $synced items'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ No items to sync'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            final synced = result['synced'] ?? 0;
            final failed = result['failed'] ?? 0;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('⚠️ Synced $synced, failed $failed items'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }

          // Refresh the UI
          ref.invalidate(pendingSyncDaoProvider(userId));
        }
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Sync error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSyncQueueView(WidgetRef ref, BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadSyncQueue(ref),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 8),
                Text(
                  'Try logging out and back in',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        }

        final items = snapshot.data ?? [];

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, size: 64, color: Colors.green),
                const SizedBox(height: 16),
                const Text('Sync queue is empty!'),
                const SizedBox(height: 16),
                const Text(
                  'Click "Populate Data" to add test data',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Summary Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatusCount(
                    'Pending',
                    items.where((i) => i['sync_status'] == 0).length,
                    Colors.orange,
                  ),
                  _buildStatusCount(
                    'Syncing',
                    items.where((i) => i['sync_status'] == 1).length,
                    Colors.blue,
                  ),
                  _buildStatusCount(
                    'Failed',
                    items.where((i) => i['sync_status'] == 3).length,
                    Colors.red,
                  ),
                ],
              ),
            ),
            // List of items
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final syncStatus = item['sync_status'] as int;
                  final retryCount = item['retry_count'] as int? ?? 0;
                  final lastError = item['last_error'] as String?;

                  Color statusColor;
                  String statusText;
                  IconData statusIcon;

                  switch (syncStatus) {
                    case 0:
                      statusColor = Colors.orange;
                      statusText = 'PENDING';
                      statusIcon = Icons.hourglass_empty;
                      break;
                    case 1:
                      statusColor = Colors.blue;
                      statusText = 'SYNCING';
                      statusIcon = Icons.sync;
                      break;
                    case 2:
                      statusColor = Colors.green;
                      statusText = 'COMPLETED';
                      statusIcon = Icons.check_circle;
                      break;
                    case 3:
                      statusColor = Colors.red;
                      statusText = 'FAILED';
                      statusIcon = Icons.error;
                      break;
                    default:
                      statusColor = Colors.grey;
                      statusText = 'UNKNOWN';
                      statusIcon = Icons.help;
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    child: ExpansionTile(
                      leading: Icon(statusIcon, color: statusColor, size: 32),
                      title: Text(
                        '${item['action']} - ${item['entity_type']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            'ID: ${item['entity_id']}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  statusText,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (retryCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Retries: $retryCount',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _DebugRow('Sync ID', item['id']),
                              const Divider(),
                              _DebugRow('Entity Type', item['entity_type']),
                              _DebugRow('Entity ID', item['entity_id']),
                              _DebugRow('Action', item['action']),
                              const Divider(),
                              _DebugRow(
                                'Queued At',
                                DateTime.fromMillisecondsSinceEpoch(
                                  item['queued_at'] as int,
                                ).toString(),
                              ),
                              _DebugRow('Retry Count', retryCount.toString()),
                              if (lastError != null) ...[
                                const Divider(),
                                const Text(
                                  'Last Error:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    lastError,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ],
                              const Divider(),
                              const Text(
                                'Payload:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Text(
                                    item['payload'] as String? ?? 'null',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusCount(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }

  Future<List<Map<String, dynamic>>> _loadSyncQueue(WidgetRef ref) async {
    try {
      final userId = _getUserId();
      if (userId == null || userId.isEmpty) {
        throw Exception('No user logged in');
      }

      final dao = await ref.read(pendingSyncDaoProvider(userId).future);
      final items = await dao.getPending();
      return items.map((e) => e.toMap()).toList();
    } catch (e) {
      print('❌ Error loading sync queue: $e');
      rethrow;
    }
  }
}

class _DebugRow extends StatelessWidget {
  final String label;
  final String value;

  const _DebugRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}
