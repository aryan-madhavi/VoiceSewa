import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:voicesewa_client/core/providers/database_provider.dart';
import 'package:voicesewa_client/features/voicebot/providers/audio_provider.dart';
import 'package:voicesewa_client/features/voicebot/providers/chat_provider.dart';
import 'package:voicesewa_client/features/voicebot/providers/speech_provider.dart';

class VoiceBotController extends Notifier<bool> {

  @override
  bool build() {
    return false; // isProcessing
  }

  /// Processes user speech and plays AI response (text + optional audio)
  Future<void> processSpeech(String msg) async {
    final AudioNotifier = ref.read(AudioProvider.notifier);
    final uid = ref.read(currentUserIdProvider);
    final lang = ref.read(speechProvider).localeId;
    if (msg.trim().isEmpty) return;

    state = true;

    try {
      final response = await http.post(
        Uri.parse(
          'https://pagales705roratu.app.n8n.cloud/webhook/converse',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'uid': uid, 'msg': msg, 'lang': lang}),
      );

      if (response.statusCode != 200) {
        throw Exception('API returned status code ${response.statusCode}');
      }

      // Decode JSON safely
      Map<String, dynamic> data;
      try {
        data = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (e) {
        throw FormatException('Failed to decode API response: $e');
      }

      // Extract fields
      final String? text = data['response'] ?? '';
      final String? base64Audio = data['base64Audio'];
      if (text == null)
        throw Exception('No valid text found in API response');
      else if (base64Audio == null)
        throw Exception('No valid base64Audio found in API response');

      // Add bot response to chat
      ref.read(chatControllerProvider.notifier).addBotMessage(text);
      // Optional: debug
      print('VoiceBot text response: $text');
      
      // Play audio
      await AudioNotifier.playBase64Audio(base64Audio);

    } catch (e) {
      print('VoiceBotController error: $e');
    } finally {
      state = false;
    }
  }
}