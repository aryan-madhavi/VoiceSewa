import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:voicesewa_client/core/database/app_database.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  print('🗄️ Initializing database...');
  return AppDatabase.instance;
});

// Usage
// final db = await ref.read(appDatabaseProvider).database;

final sqfliteDatabaseProvider = FutureProvider<Database>((ref) async {
  final appDb = ref.read(appDatabaseProvider);
  print('✅ Database initialized');
  return appDb.database;
});