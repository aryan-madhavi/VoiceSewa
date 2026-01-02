import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:voicesewa_worker/features/sync/providers/sync_providers.dart';

class SyncInitializer extends ConsumerStatefulWidget {
  final Widget child;

  const SyncInitializer({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<SyncInitializer> createState() => _SyncInitializerState();
}

class _SyncInitializerState extends ConsumerState<SyncInitializer> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        print('🔄 Starting SyncService initialization...');
        
        // Get current user
        final user = FirebaseAuth.instance.currentUser;
        if (user?.email == null) {
          print('⚠️ No user logged in, skipping sync initialization');
          return;
        }
        
        // Initialize sync service
        final syncService = await ref.read(syncServiceProvider.future);
        
        // Try to get initial status
        try {
          final status = await syncService?.getSyncStatus() ?? {'pending': 0, 'failed': 0};
          print('✅ SyncService ready - Pending: ${status['pending']}, Failed: ${status['failed']}');
        } catch (e) {
          print('⚠️ Could not get initial sync status: $e');
        }
        
      } catch (e, st) {
        print('❌ SyncService initialization failed: $e');
        print(st);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}