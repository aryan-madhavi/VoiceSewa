import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/core/providers/sync_service_provider.dart';

class SyncInitializer extends ConsumerWidget {
  final Widget child;
  
  const SyncInitializer({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the sync service provider to ensure it initializes
    final syncServiceAsync = ref.watch(syncServiceProvider);
    
    return syncServiceAsync.when(
      data: (syncService) {
        // Sync service is ready and running
        print('✅ Sync service initialized successfully');
        return child;
      },
      loading: () {
        // Show loading while initializing
        return const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Initializing sync service...'),
              ],
            ),
          ),
        );
      },
      error: (err, stack) {
        // Show error but still allow app to continue
        print('❌ Sync service initialization error: $err');
        // You can still show the child and let sync retry later
        return child;
      },
    );
  }
}