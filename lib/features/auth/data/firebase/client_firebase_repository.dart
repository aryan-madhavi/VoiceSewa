import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:voicesewa_client/shared/models/address_model.dart';
import 'package:voicesewa_client/shared/models/client_model.dart';

/// Repository for Firebase Firestore client operations
/// Handles all CRUD operations for client profiles
class ClientFirebaseRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ClientFirebaseRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Reference to clients collection
  CollectionReference<Map<String, dynamic>> get _clientsCollection =>
      _firestore.collection('clients');

  /// Get current user's UID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Get client profile by UID
  Future<ClientProfile?> getProfile(String uid) async {
    try {
      final doc = await _clientsCollection.doc(uid).get();
      
      if (!doc.exists) {
        print('📭 No profile found for UID: $uid');
        return null;
      }

      return ClientProfile.fromFirestore(doc);
    } catch (e) {
      print('❌ Error fetching profile: $e');
      rethrow;
    }
  }

  /// Get current user's profile
  Future<ClientProfile?> getCurrentUserProfile() async {
    final uid = _currentUserId;
    if (uid == null) {
      print('⚠️ No authenticated user');
      return null;
    }

    return await getProfile(uid);
  }

  /// Create or update client profile
  Future<void> upsertProfile(ClientProfile profile) async {
    try {
      await _clientsCollection.doc(profile.uid).set(
            profile.toFirestore(),
            SetOptions(merge: true),
          );
      print('✅ Profile saved for UID: ${profile.uid}');
    } catch (e) {
      print('❌ Error saving profile: $e');
      rethrow;
    }
  }

  /// Update specific fields of client profile
  Future<void> updateProfile(String uid, Map<String, dynamic> updates) async {
    try {
      await _clientsCollection.doc(uid).update(updates);
      print('✅ Profile updated for UID: $uid');
    } catch (e) {
      print('❌ Error updating profile: $e');
      rethrow;
    }
  }

  /// Delete client profile
  Future<void> deleteProfile(String uid) async {
    try {
      await _clientsCollection.doc(uid).delete();
      print('🗑️ Profile deleted for UID: $uid');
    } catch (e) {
      print('❌ Error deleting profile: $e');
      rethrow;
    }
  }

  /// Check if profile exists for user
  Future<bool> profileExists(String uid) async {
    try {
      final doc = await _clientsCollection.doc(uid).get();
      return doc.exists;
    } catch (e) {
      print('❌ Error checking profile existence: $e');
      return false;
    }
  }

  /// Check if current user has a profile
  Future<bool> currentUserHasProfile() async {
    final uid = _currentUserId;
    if (uid == null) return false;
    
    return await profileExists(uid);
  }

  /// Stream current user's profile for real-time updates
  Stream<ClientProfile?> watchCurrentUserProfile() {
    final uid = _currentUserId;
    if (uid == null) {
      return Stream.value(null);
    }

    return _clientsCollection.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ClientProfile.fromFirestore(doc);
    });
  }

  /// Stream profile by UID
  Stream<ClientProfile?> watchProfile(String uid) {
    return _clientsCollection.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ClientProfile.fromFirestore(doc);
    });
  }

  /// Update FCM token for push notifications
  Future<void> updateFcmToken(String uid, String token) async {
    try {
      await _clientsCollection.doc(uid).update({'fcm_token': token});
      print('✅ FCM token updated for UID: $uid');
    } catch (e) {
      print('❌ Error updating FCM token: $e');
      rethrow;
    }
  }

  /// Add address to client profile
  Future<void> addAddress(String uid, Address address) async {
    try {
      await _clientsCollection.doc(uid).update({
        'addresses': FieldValue.arrayUnion([address.toMap()])
      });
      print('✅ Address added for UID: $uid');
    } catch (e) {
      print('❌ Error adding address: $e');
      rethrow;
    }
  }

  /// Remove address from client profile
  Future<void> removeAddress(String uid, Address address) async {
    try {
      await _clientsCollection.doc(uid).update({
        'addresses': FieldValue.arrayRemove([address.toMap()])
      });
      print('✅ Address removed for UID: $uid');
    } catch (e) {
      print('❌ Error removing address: $e');
      rethrow;
    }
  }

  /// Add job reference to requested services
  Future<void> addRequestedJob(String uid, String jobId) async {
    try {
      final jobRef = _firestore.collection('jobs').doc(jobId);
      await _clientsCollection.doc(uid).update({
        'services.requested': FieldValue.arrayUnion([jobRef])
      });
      print('✅ Job added to requested for UID: $uid');
    } catch (e) {
      print('❌ Error adding requested job: $e');
      rethrow;
    }
  }

  /// Move job from requested to scheduled
  Future<void> scheduleJob(String uid, String jobId) async {
    try {
      final jobRef = _firestore.collection('jobs').doc(jobId);
      
      await _firestore.runTransaction((transaction) async {
        final docRef = _clientsCollection.doc(uid);
        
        transaction.update(docRef, {
          'services.requested': FieldValue.arrayRemove([jobRef]),
          'services.scheduled': FieldValue.arrayUnion([jobRef]),
        });
      });
      
      print('✅ Job scheduled for UID: $uid');
    } catch (e) {
      print('❌ Error scheduling job: $e');
      rethrow;
    }
  }

  /// Move job from scheduled to completed
  Future<void> completeJob(String uid, String jobId) async {
    try {
      final jobRef = _firestore.collection('jobs').doc(jobId);
      
      await _firestore.runTransaction((transaction) async {
        final docRef = _clientsCollection.doc(uid);
        
        transaction.update(docRef, {
          'services.scheduled': FieldValue.arrayRemove([jobRef]),
          'services.completed': FieldValue.arrayUnion([jobRef]),
        });
      });
      
      print('✅ Job completed for UID: $uid');
    } catch (e) {
      print('❌ Error completing job: $e');
      rethrow;
    }
  }

  /// Cancel a job
  Future<void> cancelJob(String uid, String jobId) async {
    try {
      final jobRef = _firestore.collection('jobs').doc(jobId);
      
      await _firestore.runTransaction((transaction) async {
        final docRef = _clientsCollection.doc(uid);
        
        // Remove from all lists and add to cancelled
        transaction.update(docRef, {
          'services.requested': FieldValue.arrayRemove([jobRef]),
          'services.scheduled': FieldValue.arrayRemove([jobRef]),
          'services.cancelled': FieldValue.arrayUnion([jobRef]),
        });
      });
      
      print('✅ Job cancelled for UID: $uid');
    } catch (e) {
      print('❌ Error cancelling job: $e');
      rethrow;
    }
  }
}