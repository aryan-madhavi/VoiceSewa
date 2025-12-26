import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/features/service_requests/domain/service_request_model.dart';
import 'package:voicesewa_client/features/sync/providers/sync_providers.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/database/daos/service_request_dao.dart';

/// Provides the ServiceRequestDao instance
final serviceRequestDaoProvider = FutureProvider<ServiceRequestDao>((ref) async {
  final db = await ref.read(sqfliteDatabaseProvider.future);
  final syncDao = await ref.read(pendingSyncDaoProvider.future); // Reuse the existing sync DAO
  return ServiceRequestDao(db, syncDao);
});

/// Provides all service requests (optionally filtered)
final serviceRequestsProvider = FutureProvider<List<ServiceRequest>>((ref) async {
  final dao = await ref.watch(serviceRequestDaoProvider.future);
  return await dao.all(); // you can add filters if needed
});

/// Provides a single service request by ID
final serviceRequestByIdProvider =
    FutureProvider.family<ServiceRequest?, String>((ref, id) async {
  final dao = await ref.watch(serviceRequestDaoProvider.future);
  return await dao.getById(id);
});
