import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:voicesewa_worker/core/providers/session_provider.dart';
import 'package:voicesewa_worker/features/auth/providers/auth_provider.dart';
import 'package:voicesewa_worker/features/voicebot/providers/audio_provider.dart';
import 'package:voicesewa_worker/features/voicebot/providers/chat_provider.dart';

class VoiceBotController extends Notifier<bool> {
  @override
  bool build() => false;

  Future<void> processAudio(String audioPath) async {
    final audioNotifier = ref.read(audioProvider.notifier);
    final uid = ref.read(currentUserProvider)?.uid;

    final file = File(audioPath);
    if (!await file.exists()) return;

    final bytes = await file.readAsBytes();
    final base64Input = base64Encode(bytes);

    state = true;

    try {
      final response = await http.post(
        Uri.parse('https://fomoha8938hutudns.app.n8n.cloud/webhook/chat'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'uid': uid, 'audio': base64Input, 'type': 'worker'}),
      );

      if (response.statusCode != 200) {
        throw Exception('API returned status ${response.statusCode}');
      }

      Map<String, dynamic> data;
      try {
        data = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (e) {
        throw FormatException('Failed to decode API response: $e');
      }

      final String? text = data['response'];
      final String? base64Reply = data['base64Audio'];
      if (base64Reply == null) throw Exception('No base64Audio in response');

      // 1. Add user message to chat immediately
      ref
          .read(chatControllerProvider.notifier)
          .addUserMessage(audioPath: audioPath);

      // 2. Save audio file to disk (fast — just writing bytes)
      final responsePath = await audioNotifier.saveBase64Audio(base64Reply);

      // 3. Add bot message to chat immediately — bubble shows now
      ref
          .read(chatControllerProvider.notifier)
          .addBotMessage(text: text, audioPath: responsePath);

      // 4. Play audio — non-blocking, chat is already updated
      if (responsePath != null) {
        audioNotifier.playFile(responsePath);
      }
    } catch (e) {
      print('VoiceBotController error: $e');
    } finally {
      state = false;
    }
  }
}
