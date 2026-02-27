import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_worker/features/voicebot/controllers/chat_controller.dart';
import 'package:voicesewa_worker/features/voicebot/models/chat_message.dart';

final chatControllerProvider =
    NotifierProvider<ChatController, List<ChatMessage>>(
  ChatController.new,
);