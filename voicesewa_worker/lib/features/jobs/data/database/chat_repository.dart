import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/chat_room_model.dart';
import '../model/message_model.dart';

class ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Stream<List<ChatRoomModel>> getMyChatRooms() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: userId)
        .orderBy('lastUpdated', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatRoomModel.fromFirestore(doc))
          .toList();
    });
  }

  Stream<List<MessageModel>> getMessages(String roomId) {
    return _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromFirestore(doc))
          .toList();
    });
  }

  Future<void> sendMessage({
    required String roomId,
    required String message,
    required String receiverId,
    required String myName,
  }) async {
    final myId = _auth.currentUser!.uid;
    final timestamp = FieldValue.serverTimestamp();

    await _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .add({
      'originalMsg': message,
      'senderId': myId,
      'receiverId': receiverId,
      'timestamp': timestamp,
      'detectedLanguage': 'en',
      'translatedLanguages': {
        'engMsg': '', 'hinMsg': '', 'gujMsg': '', 'marMsg': ''
      },
    });

    await _firestore.collection('chat_rooms').doc(roomId).update({
      'lastMessage': {
        'original': message,
        'senderId': myId,
      },
      'lastUpdated': timestamp,
    });
  }

  static String getChatRoomId(String userA, String userB) {
    return userA.hashCode <= userB.hashCode
        ? '${userA}_${userB}'
        : '${userB}_${userA}';
  }
}