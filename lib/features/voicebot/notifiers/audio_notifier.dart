import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:voicesewa_worker/features/voicebot/models/audio_state.dart';

class AudioNotifier extends Notifier<AudioState> {
  static const int _maxFiles = 20;
  static const String _recordingsFolder = 'voicebot/recordings';
  static const String _responsesFolder = 'voicebot/responses';

  late final AudioRecorder _recorder;
  late final AudioPlayer _player;

  @override
  AudioState build() {
    _recorder = AudioRecorder();
    _player = AudioPlayer();

    ref.onDispose(() async {
      await _recorder.stop();
      await _recorder.dispose();
      await _player.stop();
      await _player.dispose();
    });

    return const AudioState();
  }

  // ─── Directory helpers ───────────────────────────────────────────────────

  Future<Directory> _getDir(String subfolder) async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/$subfolder');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<void> _pruneFiles(Directory dir) async {
    final files = dir.listSync().whereType<File>().toList()
      ..sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));
    while (files.length > _maxFiles) {
      await files.removeAt(0).delete();
    }
  }

  // ─── Recording ───────────────────────────────────────────────────────────

  Future<void> startRecording() async {
    if (!await _recorder.hasPermission()) {
      state = state.copyWith(error: 'Microphone permission denied');
      return;
    }

    final dir = await _getDir(_recordingsFolder);
    final path = '${dir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );

    state = state.copyWith(isRecording: true, error: null);
  }

  Future<String?> stopRecording() async {
    final path = await _recorder.stop();
    state = state.copyWith(isRecording: false);

    if (path == null) {
      state = state.copyWith(error: 'Recording failed — no file produced');
      return null;
    }

    final dir = await _getDir(_recordingsFolder);
    await _pruneFiles(dir);
    return path;
  }

  // ─── Playback ────────────────────────────────────────────────────────────

  /// Saves [base64Audio] to disk and returns the path WITHOUT playing.
  /// Call [playFile] separately so the chat bubble shows immediately.
  Future<String?> saveBase64Audio(String base64Audio) async {
    if (base64Audio.trim().isEmpty) {
      state = state.copyWith(error: 'Audio data is empty');
      return null;
    }

    Uint8List bytes;
    try {
      bytes = base64Decode(base64Audio);
      if (bytes.isEmpty) throw Exception('Decoded audio is empty');
    } catch (e) {
      state = state.copyWith(error: 'Failed to decode Base64 audio: $e');
      return null;
    }

    final dir = await _getDir(_responsesFolder);
    final path =
        '${dir.path}/resp_${DateTime.now().millisecondsSinceEpoch}.mp3';
    await File(path).writeAsBytes(bytes);
    await _pruneFiles(dir);
    return path;
  }

  /// Plays any locally stored audio file (used for auto-play + bubble replay).
  Future<void> playFile(String path) async {
    await _player.stop();
    try {
      await _player.setAudioSource(AudioSource.file(path));
      await _player.setVolume(1.0);
      state = state.copyWith(isSpeaking: true, error: null);
      await _player.play();

      _player.playerStateStream.listen((ps) {
        if (ps.processingState == ProcessingState.completed) {
          state = state.copyWith(isSpeaking: false);
        }
      });
    } catch (e) {
      state = state.copyWith(isSpeaking: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
      state = state.copyWith(isSpeaking: false);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}
