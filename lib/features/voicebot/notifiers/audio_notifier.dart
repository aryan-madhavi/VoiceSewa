import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:voicesewa_worker/features/voicebot/models/audio_state.dart';

/// Riverpod Notifier for playing Base64 audio
class AudioNotifier extends Notifier<AudioState> {
  late final AudioPlayer _audioPlayer;
  @override
  AudioState build() {
    _audioPlayer = AudioPlayer();
    ref.onDispose(() async {
      await _audioPlayer.stop();
      await _audioPlayer.dispose();
    });
    return const AudioState();
  }

  /// Play audio from a Base64 string
  Future<void> playBase64Audio(String base64Audio) async {
    if (base64Audio.trim().isEmpty) {
      state = state.copyWith(error: 'Audio data is empty');
      return;
    }

    // Decode Base64
    Uint8List audioBytes;
    try {
      audioBytes = base64Decode(base64Audio);
      if (audioBytes.isEmpty) throw Exception('Decoded audio is empty');
    } catch (e) {
      throw FormatException('Failed to decode Base64 audio: $e');
    }

    // Create a temporary file
    final tempDir = await getApplicationDocumentsDirectory();
    final tempFile = File('${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.ogg');
    await tempFile.writeAsBytes(audioBytes);

    print('Decoded audio bytes length: ${audioBytes.length}');
    print('Saved audio file size: ${tempFile.lengthSync()}');
    print('Audio file path: ${tempFile.path}');
    
    state = state.copyWith(isSpeaking: true, error: null);
    
    try {
      await _audioPlayer.setAudioSource(AudioSource.file(tempFile.path));
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play();
      
      _audioPlayer.playerStateStream.listen((playerState) {
        if (playerState.processingState == ProcessingState.completed) {
          state = state.copyWith(isSpeaking: false);
        }
      });
    } catch (e) {
      state = state.copyWith(isSpeaking: false, error: e.toString());
      rethrow;
    } finally {
      // Cleanup
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  /// Stop playing immediately
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      state = state.copyWith(isSpeaking: false);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}