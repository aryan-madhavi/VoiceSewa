import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sync_providers.dart';
import '../../../core/providers/database_provider.dart';

class SyncDebugPage extends ConsumerWidget {
  const SyncDebugPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if user has database first
    final userHasDb = ref.watch(userHasDatabaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Queue Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(syncServiceProvider);
              ref.invalidate(pendingSyncDaoProvider);
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          try {
            final syncAsync = ref.read(syncServiceProvider);

            await syncAsync.whenData((syncService) async {
              await syncService.syncPending();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sync triggered')),
                );
                ref.invalidate(pendingSyncDaoProvider);
              }
            });
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Sync failed: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        icon: const Icon(Icons.sync),
        label: const Text('Force Sync'),
      ),
    );
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
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.green),
                SizedBox(height: 16),
                Text('Sync queue is empty!'),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: items.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final item = items[index];
            final syncStatus = item['sync_status'] as int;
            final retryCount = item['retry_count'] as int? ?? 0;
            final lastError = item['last_error'] as String?;

            Color statusColor;
            String statusText;
            switch (syncStatus) {
              case 0:
                statusColor = Colors.orange;
                statusText = 'PENDING';
                break;
              case 1:
                statusColor = Colors.blue;
                statusText = 'SYNCING';
                break;
              case 2:
                statusColor = Colors.green;
                statusText = 'COMPLETED';
                break;
              case 3:
                statusColor = Colors.red;
                statusText = 'FAILED';
                break;
              default:
                statusColor = Colors.grey;
                statusText = 'UNKNOWN';
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                leading: Icon(
                  syncStatus == 3 ? Icons.error : Icons.sync,
                  color: statusColor,
                ),
                title: Text(
                  '${item['action']} - ${item['entity_type']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ID: ${item['entity_id']}'),
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
                          Text(
                            'Retries: $retryCount',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.orange,
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
                                  item['queued_at'] as int)
                              .toString(),
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
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _loadSyncQueue(WidgetRef ref) async {
    try {
      final dao = await ref.read(pendingSyncDaoProvider.future);
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
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}