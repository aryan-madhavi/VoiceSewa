import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/sync_providers.dart';

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
  bool _initialized = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_initialized) return;
      _initialized = true;

      try {
        final syncService = await ref.read(syncServiceProvider.future);
        syncService.initialize();

        print('✅ SyncService initialized');
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
