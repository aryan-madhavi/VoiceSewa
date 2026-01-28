import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:voicesewa_client/core/database/app_database.dart';

/// Provider for user-specific database instance
/// Automatically initializes database for logged-in user
final sqfliteDatabaseProvider = FutureProvider.autoDispose<Database>((ref) async {
  print('🗄️ Fetching user-specific database...');
  
  try {
    // Get current user from Firebase Auth
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final userEmail = firebaseUser?.email;
    
    if (userEmail == null) {
      throw StateError('No user logged in. Cannot access database.');
    }
    
    print('👤 Getting database for: $userEmail');
    
    // Initialize database for this user
    ClientDatabase.instanceForUser(userEmail);
    
    // Get the database instance
    final db = await ClientDatabase.instance.database;
    print('✅ User database loaded successfully for $userEmail');
    
    return db;
  } catch (e) {
    print('❌ Error loading database: $e');
    rethrow;
  }
});

/// Provider to check if current user has a database
final userHasDatabaseProvider = FutureProvider.autoDispose<bool>((ref) async {
  final firebaseUser = FirebaseAuth.instance.currentUser;
  final userId = firebaseUser?.email;
  
  if (userId == null) return false;
  
  return await ClientDatabase.userDatabaseExists(userId);
});

/// Provider to get current user ID
final currentUserIdProvider = Provider<String?>((ref) {
  return FirebaseAuth.instance.currentUser?.uid;
});