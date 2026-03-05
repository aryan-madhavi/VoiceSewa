// lib/features/translate_call/data/call_history_repository.dart
//
// Read / delete operations on the per-user call_history subcollection.
// Writes are done by TranslateCallRepository (which already has a
// Firestore batch open for the main call doc).

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants.dart';
import '../domain/call_history_entry.dart';

class CallHistoryRepository {
  CallHistoryRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _historyCol(String uid) =>
      _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .collection(AppConstants.callHistorySubcollection);

  // ── Watch ─────────────────────────────────────────────────────────────────
  // Returns a stream of the 50 most recent entries for [uid], newest first.
  // The stream re-emits whenever Firestore changes (real-time).

  Stream<List<CallHistoryEntry>> watchHistory(String uid) {
    return _historyCol(uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) =>
            snap.docs.map(CallHistoryEntry.fromFirestore).toList());
  }

  // ── Delete ────────────────────────────────────────────────────────────────
  // Removes a single entry from the user's history subcollection.
  // Does NOT delete the main calls/{sessionId} doc — that stays for
  // the other participant's history.

  Future<void> deleteEntry(String uid, String sessionId) =>
      _historyCol(uid).doc(sessionId).delete();
}