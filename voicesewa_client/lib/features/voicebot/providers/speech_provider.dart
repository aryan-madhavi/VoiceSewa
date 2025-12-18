import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/features/voicebot/providers/speech_notifier.dart';
import 'package:voicesewa_client/features/voicebot/providers/speech_state.dart';

/// Riverpod Provider
final speechProvider = NotifierProvider<SpeechNotifier, SpeechState>(
  () => SpeechNotifier(),
);