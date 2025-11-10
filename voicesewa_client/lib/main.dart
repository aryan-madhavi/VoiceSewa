import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/constants/core/string_constants.dart';
import 'package:voicesewa_client/firebase_options.dart';
import 'package:voicesewa_client/providers/sync_service_provider.dart';
import 'package:voicesewa_client/routes/navigation_routes.dart';
import 'package:voicesewa_client/screens/core/app_gate.dart';
import 'package:voicesewa_client/theme/light_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: StringConstants.appName,
      theme: lightThemeData,
      home: const SyncInitializer( child: AppGate()),
      routes: AppRoutes.routes,
    );
  }
}


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