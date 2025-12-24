import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/features/voicebot/models/chat_message.dart';

class ChatController extends Notifier<List<ChatMessage>> {
  @override
  List<ChatMessage> build() => [];

  void addUserMessage(String text) {
    state = [
      ...state,
      ChatMessage(role: ChatRole.user, text: text),
    ];
  }

  void addBotMessage(String text) {
    state = [
      ...state,
      ChatMessage(role: ChatRole.bot, text: text),
    ];
  }

  void clear() => state = [];
}