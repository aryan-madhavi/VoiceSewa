import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/features/sync/providers/sync_providers.dart';

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
      final syncAsync = ref.read(syncServiceProvider);
      
      // unwrap AsyncValue
      await syncAsync.when(
        data: (syncService) async {
          await syncService.syncPending();

          // Refresh the pending/failed counts
          ref.invalidate(syncStatusProvider);

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Sync triggered')),
          );
        },
        loading: () {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('SyncService is loading...')),
          );
        },
        error: (err, _) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Sync error: $err'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Sync error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
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

//
// ==========================
// Floating Action Button
// ==========================
//

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
      final syncAsync = ref.read(syncServiceProvider);
  
      // unwrap AsyncValue
      await syncAsync.when(
        data: (syncService) async {
          await syncService.syncPending(); // trigger sync
  
          // refresh sync status counts
          ref.invalidate(syncStatusProvider);
  
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Sync triggered')),
          );
        },
        loading: () {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('SyncService is still loading...')),
          );
        },
        error: (err, _) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Sync error: $err'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
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
