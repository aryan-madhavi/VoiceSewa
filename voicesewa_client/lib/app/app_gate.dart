import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/core/database/app_database.dart';
import 'package:voicesewa_client/core/widgets/layout/root_scaffold.dart';
import 'package:voicesewa_client/features/auth/presentation/login_screen.dart';
import 'package:voicesewa_client/features/auth/providers/session_provider.dart';
import 'package:voicesewa_client/features/sync/presentation/sync_initializer.dart';

class AppGate extends ConsumerStatefulWidget {
  const AppGate({Key? key}) : super(key: key);

  @override
  ConsumerState<AppGate> createState() => _AppGateState();
}

class _AppGateState extends ConsumerState<AppGate> {
  bool _isDatabaseInitialized = false;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    // Initialize database on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDatabaseIfNeeded();
    });
  }

  Future<void> _initializeDatabaseIfNeeded() async {
    if (_isInitializing || _isDatabaseInitialized) return;

    setState(() => _isInitializing = true);

    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      
      if (firebaseUser?.email != null) {
        final userEmail = firebaseUser!.email!;
        print('👤 Initializing database for logged-in user: $userEmail');
        
        // Initialize database for this user
        ClientDatabase.instanceForUser(userEmail);
        
        // Ensure database is accessible
        await ClientDatabase.instance.database;
        print('✅ Database initialized successfully');
      }

      setState(() {
        _isDatabaseInitialized = true;
        _isInitializing = false;
      });
    } catch (e) {
      print('❌ Database initialization error: $e');
      setState(() => _isInitializing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionStatus = ref.watch(sessionNotifierProvider);

    // Show loading during initialization
    if (_isInitializing) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing app...'),
            ],
          ),
        ),
      );
    }

    switch (sessionStatus) {
      case SessionStatus.loading:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case SessionStatus.loggedIn:
        return const SyncInitializer(child: RootScaffold());
      case SessionStatus.loggedOut:
        return const AuthScreen();
    }
  }
}