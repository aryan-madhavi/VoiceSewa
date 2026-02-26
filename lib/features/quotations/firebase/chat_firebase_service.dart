import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voicesewa_client/shared/models/quotation_model.dart';

/// Firebase service for chat messages stored under a quotation's subcollection:
/// jobs/{jobId}/quotations/{quotationId}/messages/{msgId}
class ChatFirebaseService {
  final FirebaseFirestore _firestore;

  ChatFirebaseService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _messagesRef(
    String jobId,
    String quotationId,
  ) {
    return _firestore
        .collection('jobs')
        .doc(jobId)
        .collection('quotations')
        .doc(quotationId)
        .collection('messages');
  }

  /// Stream all messages for a quotation, ordered by sent_at ascending
  Stream<List<ChatMessage>> watchMessages(String jobId, String quotationId) {
    return _messagesRef(jobId, quotationId)
        .orderBy('sent_at', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatMessage.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Send a message
  Future<void> sendMessage({
    required String jobId,
    required String quotationId,
    required String senderUid,
    required String senderName,
    required String text,
  }) async {
    try {
      await _messagesRef(jobId, quotationId).add({
        'sender_uid': senderUid,
        'sender_name': senderName,
        'text': text.trim(),
        'is_worker': false,
        'sent_at': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('❌ Error sending message: $e');
      rethrow;
    }
  }
}
