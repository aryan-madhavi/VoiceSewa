import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voicesewa_client/shared/models/address_model.dart';
import 'package:voicesewa_client/shared/models/client_model.dart';

/// Firebase service for client profile operations
class ClientFirebaseService {
  final FirebaseFirestore _firestore;
  static const String _collectionName = 'clients';

  ClientFirebaseService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance {
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(_collectionName);

  /// Get client by UID (Firebase Auth UID used as client_uid)
  Future<ClientProfile?> getClient(String clientUid) async {
    try {
      print('📖 Fetching client with UID: $clientUid');

      final snapshot = await _collection.doc(clientUid).get();

      if (snapshot.exists) {
        print('✅ Client document found');
        final data = snapshot.data()!;
        print('📄 Client data keys: ${data.keys.toList()}');

        if (data.containsKey('addresses')) {
          final addresses = data['addresses'] as List?;
          print('📍 Raw addresses count: ${addresses?.length ?? 0}');
        } else {
          print('⚠️ No addresses field in document');
        }

        return ClientProfile.fromMap(clientUid, data);
      }

      print('❌ Client document NOT found for UID: $clientUid');
      print(
        '💡 Make sure the document ID in Firestore matches the Firebase Auth UID',
      );
      return null;
    } catch (e, stackTrace) {
      print('❌ Error fetching client: $e');
      print('📚 Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Stream client updates
  Stream<ClientProfile?> watchClient(String clientUid) {
    print('👀 Watching client with UID: $clientUid');

    return _collection.doc(clientUid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        print('🔄 Client snapshot received');
        final data = snapshot.data()!;

        if (data.containsKey('addresses')) {
          final addresses = data['addresses'] as List?;
          print('📍 Addresses in snapshot: ${addresses?.length ?? 0}');
        }

        return ClientProfile.fromMap(clientUid, data);
      }

      print('⚠️ Client snapshot does NOT exist for UID: $clientUid');
      return null;
    });
  }

  /// Add new address to client
  Future<void> addAddress(String clientUid, Address address) async {
    try {
      print('📍 Adding address for client: $clientUid');

      await _collection.doc(clientUid).update({
        'addresses': FieldValue.arrayUnion([address.toMap()]),
      });

      print('✅ Address added');
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
      print('📍 Updating addresses for client: $clientUid');

      await _collection.doc(clientUid).update({
        'addresses': addresses.map((a) => a.toMap()).toList(),
      });

      print('✅ Addresses updated');
    } catch (e) {
      print('❌ Error updating addresses: $e');
      rethrow;
    }
  }
}
