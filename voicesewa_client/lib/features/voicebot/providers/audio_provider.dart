import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/features/voicebot/models/audio_state.dart';
import 'package:voicesewa_client/features/voicebot/notifiers/audio_notifier.dart';

/// Riverpod Provider for Text-to-Speech
final AudioProvider = NotifierProvider<AudioNotifier, AudioState>(
  () => AudioNotifier(),
);