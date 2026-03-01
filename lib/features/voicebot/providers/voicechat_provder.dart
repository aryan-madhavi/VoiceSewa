import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_worker/features/voicebot/controllers/voicebot_controller.dart';

final voiceBotControllerProvider = NotifierProvider<VoiceBotController, bool>(
  VoiceBotController.new,
);
