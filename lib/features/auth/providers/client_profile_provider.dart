import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/database/daos/client_profile_dao.dart';
import '../../../features/sync/providers/sync_providers.dart'; // ✅ Import sync providers
import '../domain/client_model.dart';
import 'auth_provider.dart';

/// Provides ClientProfileDao with sync capability
final clientProfileDaoProvider = FutureProvider.autoDispose<ClientProfileDao>((
  ref,
) async {
  print('🔧 Creating ClientProfileDao with sync support...');

  final db = await ref.read(sqfliteDatabaseProvider.future);
  final syncDao = await ref.read(
    pendingSyncDaoProvider.future,
  ); // ✅ Add syncDao

  print('✅ ClientProfileDao ready with sync');
  return ClientProfileDao(db, syncDao); // ✅ Pass both dependencies
});

/// Provides current logged-in user's profile
final currentClientProfileProvider = FutureProvider.autoDispose<ClientProfile?>(
  (ref) async {
    final dao = await ref.watch(clientProfileDaoProvider.future);
    final loggedInUser = await ref.watch(loggedInUserProvider.future);

    if (loggedInUser == null) {
      print('⏭️ No logged-in user, skipping profile fetch');
      return null;
    }

    final clientId =
        loggedInUser['username'] as String; // map username → client_id
    print('👤 Fetching profile for: $clientId');

    final profile = await dao.get(clientId);

    if (profile != null) {
      print('✅ Profile loaded for $clientId');
    } else {
      print('⚠️ No profile found for $clientId');
    }

    return profile;
  },
);

/* ===== USAGE EXAMPLE =====

// In your widget:
final userProfileAsync = ref.watch(currentClientProfileProvider);

return userProfileAsync.when(
  data: (profile) {
    if (profile == null) return const Text('No profile found');
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

// To create/update profile:
Future<void> updateProfile() async {
  final dao = await ref.read(clientProfileDaoProvider.future);
  final profile = ClientProfile(
    clientId: 'user@example.com',
    name: 'John Doe',
    phone: '+1234567890',
    language: 'en',
    address: '123 Main St',
    updatedAt: DateTime.now().millisecondsSinceEpoch,
  );
  await dao.upsert(profile); // ✅ Automatically syncs to Firestore!
}

*/
