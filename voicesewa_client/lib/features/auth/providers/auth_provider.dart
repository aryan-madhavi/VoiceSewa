import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/daos/db_login_dao.dart';
import '../data/repositories/auth_repository.dart';

// DAO provider
final dbLoginDaoProvider = Provider<DbLoginDao>((ref) {
  return DbLoginDao();
});

// Repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dao = ref.watch(dbLoginDaoProvider);
  return AuthRepository(dao);
});

// Logged-in user provider
final loggedInUserProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  return await repo.getLoggedInUser();
});

// Session validation provider
final sessionValidProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  return await repo.isSessionValid();
});
