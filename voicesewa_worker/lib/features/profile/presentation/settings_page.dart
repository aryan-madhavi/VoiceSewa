import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_worker/features/auth/data/services/logout_service.dart';
import 'package:voicesewa_worker/features/sync/presentation/sync_debug_page.dart';
import 'package:voicesewa_worker/features/sync/providers/sync_providers.dart';
import '../../../core/constants/helper_function.dart';
import '../../../core/extensions/context_extensions.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _darkMode = false;
  bool _isSyncing = false;

  Future<void> _handleSync() async {
    if (_isSyncing) return;

    setState(() => _isSyncing = true);

    try {
      final syncAsync = ref.read(syncServiceProvider);

      await syncAsync.when(
        data: (syncService) async {
          if (syncService == null) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⚠️ Sync service not available'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }

          // Call syncPending and get the result
          final result = await syncService.syncPending();

          // Refresh sync status
          ref.invalidate(syncStatusProvider);

          if (!mounted) return;

          // Handle different result scenarios
          if (result['noInternet'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ No internet connection'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          } else if (result['paused'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⏸️ Sync is currently paused'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
              ),
            );
          } else if (result['skipped'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⏳ Sync already in progress'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
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
                  content: Text('✅ All data is already synced'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } else {
            // Partial success
            final synced = result['synced'] ?? 0;
            final failed = result['failed'] ?? 0;

            if (synced > 0 && failed > 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('⚠️ Synced $synced items, $failed failed'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 3),
                ),
              );
            } else if (failed > 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('❌ Failed to sync $failed items'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            } else {
              // Unknown error
              final error = result['error'] as String?;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('❌ Sync error: ${error ?? "Unknown error"}'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
        },
        loading: () {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⏳ Sync service is loading...'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        error: (err, _) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Sync service error: $err'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Unexpected error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    final logoutHandler = LogoutHandler(ref: ref, context: context);
    final success = await logoutHandler.logout();

    if (success && mounted) {
      // Navigation will be handled automatically by AppGate
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final syncStatusAsync = ref.watch(syncStatusProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          context.loc.settings,
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Preferences Section
          Text(
            context.loc.preferences,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          settingsPageBuildSwitchTile(
            context.loc.pushNotifications,
            context.loc.receiveJobAlerts,
            _notificationsEnabled,
            (val) {
              setState(() => _notificationsEnabled = val);
            },
          ),
          settingsPageBuildSwitchTile(
            context.loc.darkMode,
            context.loc.reduceEyeStrain,
            _darkMode,
            (val) {
              setState(() => _darkMode = val);
            },
          ),

          const SizedBox(height: 30),

          // Account Section
          Text(
            context.loc.account,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          settingsPageBuildActionTile(
            context.loc.changePassword,
            Icons.lock_outline,
            () {},
          ),
          settingsPageBuildActionTile(
            context.loc.language,
            Icons.language,
            () {},
          ),
          settingsPageBuildActionTile(
            context.loc.privacyPolicy,
            Icons.privacy_tip_outlined,
            () {},
          ),

          const SizedBox(height: 30),

          // Sync Section Header
          const Text(
            'Data Sync',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 10),

          // Sync Status Card
          syncStatusAsync.when(
            data: (status) {
              final pendingCount = status['pending'] ?? 0;
              final failedCount = status['failed'] ?? 0;
              return _buildSyncCard(
                pendingCount: pendingCount,
                failedCount: failedCount,
              );
            },
            loading: () => _buildSyncCard(
              pendingCount: 0,
              failedCount: 0,
              isLoading: true,
            ),
            error: (_, __) =>
                _buildSyncCard(pendingCount: 0, failedCount: 0, hasError: true),
          ),

          const SizedBox(height: 30),

          settingsPageBuildActionTile(
            'Sync Debug',
            Icons.bug_report,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SyncDebugPage()),
            ),
          ),

          const SizedBox(height: 30),
          // Logout Section Header
          const Text(
            'Session',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 10),

          // Logout Button (using your helper function style)
          settingsPageBuildActionTile(
            'Logout',
            Icons.logout,
            _handleLogout,
            isDestructive: false, // Orange, not red
          ),

          const SizedBox(height: 30),

          // Danger Zone Section
          const Text(
            'Danger Zone',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          ),
          const SizedBox(height: 10),

          // Delete Account
          settingsPageBuildActionTile(
            context.loc.deleteAccount,
            Icons.delete_outline,
            () {
              _showDeleteAccountDialog();
            },
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  /// Build sync card widget
  Widget _buildSyncCard({
    required int pendingCount,
    required int failedCount,
    bool isLoading = false,
    bool hasError = false,
  }) {
    // Determine status
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isLoading) {
      statusColor = Colors.grey;
      statusText = 'Checking sync status...';
      statusIcon = Icons.hourglass_empty;
    } else if (hasError) {
      statusColor = Colors.red;
      statusText = 'Error loading sync status';
      statusIcon = Icons.error_outline;
    } else if (failedCount > 0) {
      statusColor = Colors.red;
      statusText = '$failedCount failed items';
      statusIcon = Icons.sync_problem;
    } else if (pendingCount > 0) {
      statusColor = Colors.orange;
      statusText = '$pendingCount items pending';
      statusIcon = Icons.sync;
    } else {
      statusColor = Colors.green;
      statusText = 'All data synced';
      statusIcon = Icons.check_circle;
    }

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
          Row(
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
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
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
          ),

          // Sync Button (only show if not loading/error)
          if (!isLoading && !hasError) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSyncing ? null : _handleSync,
                style: ElevatedButton.styleFrom(
                  backgroundColor: statusColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBackgroundColor: Colors.grey,
                ),
                icon: _isSyncing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.sync, size: 18),
                label: Text(
                  _isSyncing ? 'Syncing...' : 'Sync Now',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],

          // Additional info for failed items
          if (failedCount > 0 && !isLoading) ...[
            const SizedBox(height: 12),
            Container(
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
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Show delete account confirmation dialog
  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete Account'),
            ],
          ),
          content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Account deletion feature coming soon'),
                  ),
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
