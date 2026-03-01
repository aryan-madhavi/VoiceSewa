import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:voicesewa_worker/features/voicebot/models/speech_state.dart';
import 'package:voicesewa_worker/features/voicebot/providers/chat_provider.dart';
import 'package:voicesewa_worker/features/voicebot/providers/voicechat_provder.dart';

class SpeechNotifier extends Notifier<SpeechState> {
  late final SpeechToText _speechToText;

  @override
  SpeechState build() {
    _speechToText = SpeechToText();
    _initSpeech();

    // Cleanup on dispose
    ref.onDispose(() {
      if (_speechToText.isListening) _speechToText.stop();
    });

    return const SpeechState();
  }

  /// Initialize speech recognition and fetch available locales
  Future<void> _initSpeech() async {
    try {
      bool available = await _speechToText.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            state = state.copyWith(isListening: false);
          }
        },
        onError: (error) {
          state = state.copyWith(error: error.errorMsg, isListening: false);
        },
      );

      if (!available) {
        state = state.copyWith(
          isInitialized: false,
          error: 'Speech recognition not available',
        );
        return;
      }

      // Get all available locales
      List<LocaleName> locales = await _speechToText.locales();

      // Detect system default
      LocaleName? systemLocale = await _speechToText.systemLocale();
      String defaultLocale = systemLocale?.localeId ?? 'en_US';

      state = state.copyWith(
        isInitialized: true,
        localeId: defaultLocale,
        availableLocales: locales,
      );
    } catch (e) {
      state = state.copyWith(
        isInitialized: false,
        error: 'Failed to initialize speech recognition',
      );
    }
  }

  /// Start listening with optional locale selection
  Future<void> startListening({String? localeId}) async {
    if (!state.isInitialized) {
      await _initSpeech();
      if (!state.isInitialized) return;
    }

    // Use selected locale or fallback to current state
    final lang = localeId ?? state.localeId;

    state = state.copyWith(
      recognizedText: '',
      isListening: true,
      error: null,
      localeId: lang,
    );

    await _speechToText.listen(
      onResult: _onSpeechResult,
      localeId: lang,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        cancelOnError: true,
        partialResults: true,
      ),
    );
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    print('Speech result (${state.localeId}): ${result.recognizedWords}');
    state = state.copyWith(recognizedText: result.recognizedWords);
    if (result.finalResult) {
      final text = result.recognizedWords.trim();
      stopListening();
      ref.read(chatControllerProvider.notifier).addUserMessage();
      ref.read(voiceBotControllerProvider.notifier).processAudio(text);
    }
  }

  Future<void> stopListening() async {
    if (_speechToText.isListening) await _speechToText.stop();
    state = state.copyWith(isListening: false);
  }

  void clearText() {
    state = state.copyWith(recognizedText: '', error: null);
  }

  /// Change the current language dynamically
  void setLocale(String newLocaleId) {
    state = state.copyWith(localeId: newLocaleId);
  }

  /// Get all available locales
  List<LocaleName> getAvailableLocales() => state.availableLocales;
}
