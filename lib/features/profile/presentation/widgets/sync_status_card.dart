import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_worker/features/sync/data/sync_service.dart';
import 'package:voicesewa_worker/features/sync/providers/sync_providers.dart';

class SyncStatusCard extends ConsumerStatefulWidget {
  final String userId;
  final int pendingCount;
  final int failedCount;
  final bool isLoading;
  final bool hasError;

  const SyncStatusCard({
    super.key,
    required this.userId,
    required this.pendingCount,
    required this.failedCount,
    this.isLoading = false,
    this.hasError = false,
  });

  @override
  ConsumerState<SyncStatusCard> createState() => _SyncStatusCardState();
}

class _SyncStatusCardState extends ConsumerState<SyncStatusCard> {
  bool _isSyncing = false;

  Future<void> _handleSync() async {
    if (_isSyncing || widget.userId.isEmpty) return;

    setState(() => _isSyncing = true);

    try {
      final WorkerSyncService? syncService = await ref.read(
        syncServiceProvider(widget.userId).future,
      );

      if (syncService == null) {
        if (!mounted) return;
        _showSnackBar('⚠️ Sync service not available', Colors.orange);
        return;
      }

      final result = await syncService.syncPending();
      ref.invalidate(syncStatusProvider);

      if (!mounted) return;
      _showSyncResult(result);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('❌ Sync error: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  void _showSyncResult(Map<String, dynamic> result) {
    if (result['noInternet'] == true) {
      _showSnackBar('❌ No internet connection', Colors.red);
    } else if (result['skipped'] == true) {
      _showSnackBar('⏳ Sync already in progress', Colors.orange);
    } else if (result['success'] == true) {
      final synced = result['synced'] ?? 0;
      _showSnackBar(
        synced > 0
            ? '✅ Successfully synced $synced items'
            : '✅ All data is already synced',
        Colors.green,
      );
    } else {
      final synced = result['synced'] ?? 0;
      final failed = result['failed'] ?? 0;
      final error = result['error'] as String?;

      String message;
      Color bgColor;

      if (synced > 0 && failed > 0) {
        message = '⚠️ Synced $synced items, $failed failed';
        bgColor = Colors.orange;
      } else if (failed > 0) {
        message = '❌ Failed to sync $failed items';
        bgColor = Colors.red;
      } else {
        message = '❌ Sync error: ${error ?? "Unknown error"}';
        bgColor = Colors.red;
      }

      _showSnackBar(message, bgColor);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final statusText = _getStatusText();
    final statusIcon = _getStatusIcon();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Status Row
          _SyncStatusRow(
            statusColor: statusColor,
            statusIcon: statusIcon,
            statusText: statusText,
          ),

          // Sync Button
          if (!widget.isLoading && !widget.hasError) ...[
            const SizedBox(height: 16),
            _SyncButton(
              isSyncing: _isSyncing,
              statusColor: statusColor,
              onPressed: _handleSync,
            ),
          ],

          // Failed items warning
          if (widget.failedCount > 0 && !widget.isLoading)
            const _FailedItemsWarning(),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    if (widget.isLoading) return Colors.grey;
    if (widget.hasError) return Colors.red;
    if (widget.failedCount > 0) return Colors.red;
    if (widget.pendingCount > 0) return Colors.orange;
    return Colors.green;
  }

  String _getStatusText() {
    if (widget.isLoading) return 'Checking sync status...';
    if (widget.hasError) return 'Error loading sync status';
    if (widget.failedCount > 0) return '${widget.failedCount} failed items';
    if (widget.pendingCount > 0) return '${widget.pendingCount} items pending';
    return 'All data synced';
  }

  IconData _getStatusIcon() {
    if (widget.isLoading) return Icons.hourglass_empty;
    if (widget.hasError) return Icons.error_outline;
    if (widget.failedCount > 0) return Icons.sync_problem;
    if (widget.pendingCount > 0) return Icons.sync;
    return Icons.check_circle;
  }
}

/// Status indicator row
class _SyncStatusRow extends StatelessWidget {
  final Color statusColor;
  final IconData statusIcon;
  final String statusText;

  const _SyncStatusRow({
    required this.statusColor,
    required this.statusIcon,
    required this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(statusIcon, color: statusColor, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sync Status',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                statusText,
                style: TextStyle(color: statusColor, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Sync button
class _SyncButton extends StatelessWidget {
  final bool isSyncing;
  final Color statusColor;
  final VoidCallback onPressed;

  const _SyncButton({
    required this.isSyncing,
    required this.statusColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isSyncing ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: statusColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          disabledBackgroundColor: Colors.grey,
        ),
        icon: isSyncing
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.sync, size: 18),
        label: Text(
          isSyncing ? 'Syncing...' : 'Sync Now',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }
}

/// Warning for failed items
class _FailedItemsWarning extends StatelessWidget {
  const _FailedItemsWarning();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 16, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Some items failed to sync. Check your connection.',
                style: TextStyle(fontSize: 11, color: Colors.red.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
