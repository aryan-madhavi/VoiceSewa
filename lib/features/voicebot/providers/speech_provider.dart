import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_worker/features/voicebot/notifiers/speech_notifier.dart';
import 'package:voicesewa_worker/features/voicebot/models/speech_state.dart';

/// Riverpod Provider for Speech-to-Text
final speechProvider = NotifierProvider<SpeechNotifier, SpeechState>(
  () => SpeechNotifier(),
);