import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/core/database/app_database.dart';
import 'package:voicesewa_client/app/widgets/profile_check_handler.dart';
import 'package:voicesewa_client/app/widgets/database_init_error_screen.dart';

/// Handles the logged-in user initialization flow
///
/// Responsibilities:
/// 1. Initialize user-specific database
/// 2. Handle initialization errors with retry capability
/// 3. Proceed to profile check once database is ready
///
/// This ensures database is ALWAYS initialized before any
/// profile or app operations occur.
class LoggedInHandler extends ConsumerStatefulWidget {
  const LoggedInHandler({Key? key}) : super(key: key);

  @override
  ConsumerState<LoggedInHandler> createState() => _LoggedInHandlerState();
}

class _LoggedInHandlerState extends ConsumerState<LoggedInHandler> {
  bool _isDatabaseInitialized = false;
  bool _isInitializing = false;
  String? _initError;

  @override
  void initState() {
    super.initState();
    // Start initialization after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeUserSession();
    });
  }

  /// Initialize user-specific database
  Future<void> _initializeUserSession() async {
    // Prevent duplicate initialization
    if (_isInitializing || _isDatabaseInitialized) return;

    setState(() {
      _isInitializing = true;
      _initError = null;
    });

    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser?.email == null) {
        throw Exception('No Firebase user found');
      }

      final userEmail = firebaseUser!.email!;
      print('👤 Initializing session for: $userEmail');

      // Initialize user-specific database
      ClientDatabase.instanceForUser(userEmail);

      // Ensure database is accessible and all tables are created
      await ClientDatabase.instance.database;
      print('✅ Database initialized successfully');

      setState(() {
        _isDatabaseInitialized = true;
        _isInitializing = false;
      });
    } catch (e, stackTrace) {
      print('❌ Session initialization error: $e');
      print('Stack trace: $stackTrace');

      setState(() {
        _initError = e.toString();
        _isInitializing = false;
      });
    }
  }

  /// Retry initialization after error
  void _retryInitialization() {
    setState(() {
      _isDatabaseInitialized = false;
      _initError = null;
    });
    _initializeUserSession();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading during database initialization
    if (_isInitializing) {
      return _buildLoadingScreen();
    }

    // Show error screen if initialization failed
    if (_initError != null) {
      return DatabaseInitErrorScreen(
        error: _initError!,
        onRetry: _retryInitialization,
      );
    }

    // Database initialized successfully - proceed to profile check
    if (_isDatabaseInitialized) {
      return const ProfileCheckHandler();
    }

    // Fallback (should never reach here)
    return _buildLoadingScreen();
  }

  Widget _buildLoadingScreen() {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing your workspace...'),
          ],
        ),
      ),
    );
  }
}
