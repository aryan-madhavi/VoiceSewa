import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../data/database/chat_repository.dart';
import '../data/model/chat_room_model.dart';
import '../data/model/message_model.dart';

class ChatProvider extends ChangeNotifier {
  final ChatRepository _repository = ChatRepository();

  Stream<List<ChatRoomModel>> get myChatsStream => _repository.getMyChatRooms();

  Stream<List<MessageModel>> getMessagesStream(String roomId) {
    return _repository.getMessages(roomId);
  }

  Future<void> sendMessage(String roomId, String message, String receiverId) async {
    if (message.trim().isEmpty) return;

    await _repository.sendMessage(
      roomId: roomId,
      message: message,
      receiverId: receiverId,
      myName: 'User',
    );

  }

  Future<String> initiateChatWithClient({
    required String myId,
    required String myName,
    required String clientId,
    required String clientName,
  }) async {
    // 1. Generate the unique room ID
    final roomId = ChatRepository.getChatRoomId(myId, clientId);

    // 2. Reference the specific chat room document
    final roomRef = FirebaseFirestore.instance.collection('chat_rooms').doc(roomId);

    // 3. Check if we already have a chat history with this client
    final docSnapshot = await roomRef.get();

    if (!docSnapshot.exists) {
      // 4. If this is a brand new chat, create the Room Metadata
      await roomRef.set({
        'participants': [myId, clientId],
        'participantData': {
          myId: {
            'name': myName,
            'role': 'worker',
          },
          clientId: {
            'name': clientName,
            'role': 'client',
          }
        },
        'lastMessage': 'Chat started',
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }

    return roomId;
  }
}


// TODO: Test After Dynamic Data logic is completed