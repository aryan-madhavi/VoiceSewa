import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voicesewa_client/shared/models/address_model.dart';
import 'package:voicesewa_client/shared/models/client_model.dart';

// ==================== FIREBASE SERVICE ====================

class ClientFirebaseService {
  final FirebaseFirestore _firestore;
  static const String _collectionName = 'clients';

  ClientFirebaseService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(_collectionName);

  /// Get client profile by UID
  Future<ClientProfile?> getClient(String clientUid) async {
    try {
      final doc = await _collection.doc(clientUid).get();
      if (doc.exists) {
        return ClientProfile.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('❌ Error fetching client: $e');
      rethrow;
    }
  }

  /// Stream client profile updates
  Stream<ClientProfile?> watchClient(String clientUid) {
    return _collection.doc(clientUid).snapshots().map((doc) {
      if (doc.exists) {
        return ClientProfile.fromFirestore(doc);
      }
      return null;
    });
  }

  /// Add new address to client
  Future<void> addAddress(String clientUid, Address address) async {
    try {
      await _collection.doc(clientUid).update({
        'addresses': FieldValue.arrayUnion([address.toMap()]),
      });
    } catch (e) {
      print('❌ Error adding address: $e');
      rethrow;
    }
  }

  /// Update all addresses
  Future<void> updateAddresses(
    String clientUid,
    List<Address> addresses,
  ) async {
    try {
      await _collection.doc(clientUid).update({
        'addresses': addresses.map((a) => a.toMap()).toList(),
      });
    } catch (e) {
      print('❌ Error updating addresses: $e');
      rethrow;
    }
  }
}

// ==================== PROVIDERS ====================

/// Service provider
final clientFirebaseServiceProvider = Provider<ClientFirebaseService>((ref) {
  return ClientFirebaseService();
});

/// Get current client profile
final currentClientProvider = StreamProvider.autoDispose<ClientProfile?>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    print('⚠️ No user logged in');
    return Stream.value(null);
  }

  print('👤 Watching client profile for UID: ${user.uid}');
  final service = ref.watch(clientFirebaseServiceProvider);
  return service.watchClient(user.uid);
});

/// Get client addresses - Returns AsyncValue for proper loading/error states
final clientAddressesProvider = Provider.autoDispose<AsyncValue<List<Address>>>(
  (ref) {
    final clientAsync = ref.watch(currentClientProvider);

    return clientAsync.when(
      data: (client) {
        if (client == null) {
          print('⚠️ Client profile is null');
          return const AsyncValue.data([]);
        }
        print('📍 Addresses loaded: ${client.addresses.length}');
        return AsyncValue.data(client.addresses);
      },
      loading: () {
        print('⏳ Loading client addresses...');
        return const AsyncValue.loading();
      },
      error: (error, stack) {
        print('❌ Error loading addresses: $error');
        return AsyncValue.error(error, stack);
      },
    );
  },
);

/// Client actions provider
final clientActionsProvider = Provider<ClientActions>((ref) {
  final service = ref.watch(clientFirebaseServiceProvider);
  return ClientActions(service, ref);
});

/// Client actions class
class ClientActions {
  final ClientFirebaseService _service;
  final Ref _ref;

  ClientActions(this._service, this._ref);

  /// Add new address to current client
  Future<void> addAddress(Address address) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _service.addAddress(user.uid, address);

    // Invalidate to refresh
    _ref.invalidate(currentClientProvider);
  }

  /// Update all addresses for current client
  Future<void> updateAddresses(List<Address> addresses) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _service.updateAddresses(user.uid, addresses);

    // Invalidate to refresh
    _ref.invalidate(currentClientProvider);
  }
}