import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/core/providers/sync_service_provider.dart';

class SyncButton extends ConsumerStatefulWidget {
  const SyncButton({super.key});

  @override
  ConsumerState<SyncButton> createState() => _SyncButtonState();
}

class _SyncButtonState extends ConsumerState<SyncButton> 
    with SingleTickerProviderStateMixin {
  bool _isSyncing = false;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _handleSync() async {
    if (_isSyncing) return;

    setState(() => _isSyncing = true);
    _rotationController.repeat();

    try {
      final syncServiceAsync = ref.read(syncServiceProvider);
      
      await syncServiceAsync.when(
        data: (syncService) async {
          // Force sync
          await syncService.forceSyncNow();
          
          // FIXED: Check actual sync status after completion
          final statusAfterSync = await syncService.getSyncStatus();
          final pendingAfter = statusAfterSync['pending'] ?? 0;
          final failedAfter = statusAfterSync['failed'] ?? 0;
          
          if (mounted) {
            if (pendingAfter == 0 && failedAfter == 0) {
              // All items synced successfully
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text('✅ All items synced successfully!'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            } else if (failedAfter > 0) {
              // Some items failed
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.white),
                      const SizedBox(width: 8),
                      Text('⚠️  $failedAfter items failed to sync'),
                    ],
                  ),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 3),
                  action: SnackBarAction(
                    label: 'View',
                    textColor: Colors.white,
                    onPressed: () {
                      // Navigate to sync status page
                      Navigator.pushNamed(context, '/sync-status');
                    },
                  ),
                ),
              );
            } else {
              // Still items pending
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.schedule, color: Colors.white),
                      const SizedBox(width: 8),
                      Text('🔄 Sync in progress ($pendingAfter pending)'),
                    ],
                  ),
                  backgroundColor: Colors.blue,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
            
            // Refresh the status provider
            ref.invalidate(syncStatusProvider);
          }
        },
        loading: () async {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⏳ Sync service not ready yet'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        },
        error: (err, stack) async {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Sync failed: $err'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
      );
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
        _rotationController.stop();
        _rotationController.reset();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final syncStatusAsync = ref.watch(syncStatusProvider);

    return syncStatusAsync.when(
      data: (status) {
        final pendingCount = status['pending'] ?? 0;
        final failedCount = status['failed'] ?? 0;
        final hasItems = pendingCount > 0 || failedCount > 0;

        return Stack(
          children: [
            IconButton(
              onPressed: _isSyncing ? null : _handleSync,
              icon: RotationTransition(
                turns: _rotationController,
                child: Icon(
                  Icons.sync,
                  color: _isSyncing 
                      ? Colors.grey 
                      : hasItems 
                          ? Colors.orange 
                          : Colors.blue,
                ),
              ),
              tooltip: _isSyncing 
                  ? 'Syncing...' 
                  : hasItems
                      ? 'Sync $pendingCount pending items'
                      : 'All synced',
            ),
            if (hasItems && !_isSyncing)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: failedCount > 0 ? Colors.red : Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Center(
                    child: Text(
                      '$pendingCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => IconButton(
        onPressed: null,
        icon: const Icon(Icons.sync, color: Colors.grey),
      ),
      error: (_, __) => IconButton(
        onPressed: _handleSync,
        icon: const Icon(Icons.sync_problem, color: Colors.red),
      ),
    );
  }
}

// Alternative: Floating Action Button version
class SyncFAB extends ConsumerStatefulWidget {
  const SyncFAB({super.key});

  @override
  ConsumerState<SyncFAB> createState() => _SyncFABState();
}

class _SyncFABState extends ConsumerState<SyncFAB> 
    with SingleTickerProviderStateMixin {
  bool _isSyncing = false;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _handleSync() async {
    if (_isSyncing) return;

    setState(() => _isSyncing = true);
    _rotationController.repeat();

    try {
      final syncServiceAsync = ref.read(syncServiceProvider);
      
      await syncServiceAsync.when(
        data: (syncService) async {
          await syncService.forceSyncNow();
          
          // FIXED: Check actual sync status
          final statusAfterSync = await syncService.getSyncStatus();
          final pendingAfter = statusAfterSync['pending'] ?? 0;
          final failedAfter = statusAfterSync['failed'] ?? 0;
          
          if (mounted) {
            if (pendingAfter == 0 && failedAfter == 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text('✅ Sync completed!'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            } else if (failedAfter > 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('⚠️  $failedAfter items failed'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
            
            // Refresh status
            ref.invalidate(syncStatusProvider);
          }
        },
        loading: () async {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sync service initializing...'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        },
        error: (err, stack) async {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Sync error: $err'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      );
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
        _rotationController.stop();
        _rotationController.reset();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final syncStatusAsync = ref.watch(syncStatusProvider);

    return syncStatusAsync.when(
      data: (status) {
        final pendingCount = status['pending'] ?? 0;
        final failedCount = status['failed'] ?? 0;

        return FloatingActionButton.extended(
          heroTag: 'sync_fab',
          onPressed: _isSyncing ? null : _handleSync,
          icon: RotationTransition(
            turns: _rotationController,
            child: Icon(
              _isSyncing 
                  ? Icons.sync 
                  : failedCount > 0 
                      ? Icons.sync_problem 
                      : Icons.cloud_upload,
            ),
          ),
          label: Text(
            _isSyncing 
                ? 'Syncing...' 
                : pendingCount > 0 
                    ? 'Sync ($pendingCount)' 
                    : 'All Synced',
          ),
          backgroundColor: _isSyncing 
              ? Colors.grey 
              : failedCount > 0 
                  ? Colors.red 
                  : pendingCount > 0 
                      ? Colors.orange 
                      : Colors.green,
        );
      },
      loading: () => FloatingActionButton.extended(
        heroTag: 'sync_fab_loading',
        onPressed: null,
        icon: const Icon(Icons.hourglass_empty),
        label: const Text('Loading...'),
      ),
      error: (_, __) => FloatingActionButton.extended(
        heroTag: 'sync_fab_error',
        onPressed: _handleSync,
        icon: const Icon(Icons.error),
        label: const Text('Error'),
        backgroundColor: Colors.red,
      ),
    );
  }
}