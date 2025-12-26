import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:voicesewa_client/core/database/app_database.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});

// Usage
// final db = await ref.read(appDatabaseProvider).database;

final sqfliteDatabaseProvider = FutureProvider<Database>((ref) async {
  final appDb = ref.read(appDatabaseProvider);
  return appDb.database;
});