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
}


// TODO: Test After Dynamic Data logic is completed