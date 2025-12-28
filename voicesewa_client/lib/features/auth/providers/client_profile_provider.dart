import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/database/daos/client_profile_dao.dart';
import '../domain/client_model.dart';
import 'auth_provider.dart';

final clientProfileDaoProvider = FutureProvider.autoDispose<ClientProfileDao>((ref) async {
  final db = await ref.read(sqfliteDatabaseProvider.future);
  return ClientProfileDao(db);
});

final currentClientProfileProvider = FutureProvider.autoDispose<ClientProfile?>((ref) async {
  final dao = await ref.watch(clientProfileDaoProvider.future);
  final loggedInUser = await ref.watch(loggedInUserProvider.future);

  if (loggedInUser == null) return null;

  final clientId = loggedInUser['username'] as String; // map username → client_id
  return await dao.get(clientId);
});

/* /// Example Usage
final userProfileAsync = ref.watch(currentClientProfileProvider);

return userProfileAsync.when(
  data: (profile) {
    if (profile == null) return const Text('No user logged in');
    return Column(
      children: [
        Text('Hello ${profile.name}'),
        Text('Phone: ${profile.phone}'),
        Text('Language: ${profile.language}'),
      ],
    );
  },
  loading: () => const CircularProgressIndicator(),
  error: (e, _) => Text('Error: $e'),
);
*/