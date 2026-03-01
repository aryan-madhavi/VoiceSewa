import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_worker/features/voicebot/models/chat_message.dart';

class ChatController extends Notifier<List<ChatMessage>> {
  @override
  List<ChatMessage> build() => [];

  void addUserMessage({String? text, String? audioPath}) {
    state = [
      ...state,
      ChatMessage(role: ChatRole.user, text: text, audioPath: audioPath),
    ];
  }

  void addBotMessage({String? text, String? audioPath}) {
    state = [
      ...state,
      ChatMessage(role: ChatRole.bot, text: text, audioPath: audioPath),
    ];
  }

  void clear() => state = [];
}
