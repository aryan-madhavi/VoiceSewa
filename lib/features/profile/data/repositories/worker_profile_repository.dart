import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voicesewa_worker/shared/models/worker_model.dart';

class WorkerProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _workers => _firestore.collection('workers');

  /// Check if a worker profile document exists in Firestore.
  Future<bool> hasProfile(String uid) async {
    try {
      final doc = await _workers.doc(uid).get();
      return doc.exists;
    } catch (e) {
      print('❌ Error checking profile existence: $e');
      return false;
    }
  }

  /// Fetch the worker profile. Returns null if not found.
  Future<WorkerModel?> getProfile(String uid) async {
    try {
      final doc = await _workers.doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return WorkerModel.fromDoc(doc);
    } catch (e) {
      print('❌ Error fetching worker profile: $e');
      return null;
    }
  }

  /// Stream the worker profile for real-time updates.
  Stream<WorkerModel?> watchProfile(String uid) {
    return _workers.doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return WorkerModel.fromDoc(doc);
    });
  }

  /// Create or update the worker profile in Firestore.
  Future<bool> saveProfile(WorkerModel worker) async {
    try {
      await _workers
          .doc(worker.workerId)
          .set(worker.toMap(), SetOptions(merge: true));
      print('✅ Worker profile saved: ${worker.workerId}');
      return true;
    } catch (e) {
      print('❌ Error saving worker profile: $e');
      return false;
    }
  }

  /// Update specific fields on the worker profile.
  Future<bool> updateFields(String uid, Map<String, dynamic> fields) async {
    try {
      await _workers.doc(uid).update(fields);
      print('✅ Worker profile fields updated: $uid');
      return true;
    } catch (e) {
      print('❌ Error updating worker profile fields: $e');
      return false;
    }
  }

  /// Update the FCM token on the worker document.
  Future<void> updateFcmToken(String uid, String token) async {
    try {
      await _workers.doc(uid).set({
        'fcm_token': token,
      }, SetOptions(merge: true));
    } catch (e) {
      print('❌ Error updating FCM token: $e');
    }
  }
}
