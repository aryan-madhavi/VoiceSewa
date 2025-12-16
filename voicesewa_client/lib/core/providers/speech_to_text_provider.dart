import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class SpeechState {
  final bool isListening;
  final String recognizedText;
  final bool isInitialized;
  final String? error;
  final String localeId; // current listening locale
  final List<LocaleName> availableLocales;

  const SpeechState({
    this.isListening = false,
    this.recognizedText = '',
    this.isInitialized = false,
    this.error,
    this.localeId = 'en_US',
    this.availableLocales = const [],
  });

  SpeechState copyWith({
    bool? isListening,
    String? recognizedText,
    bool? isInitialized,
    String? error,
    String? localeId,
    List<LocaleName>? availableLocales,
  }) {
    return SpeechState(
      isListening: isListening ?? this.isListening,
      recognizedText: recognizedText ?? this.recognizedText,
      isInitialized: isInitialized ?? this.isInitialized,
      error: error,
      localeId: localeId ?? this.localeId,
      availableLocales: availableLocales ?? this.availableLocales,
    );
  }
}

class SpeechNotifier extends Notifier<SpeechState> {
  late final SpeechToText _speechToText;
  Timer? _silenceTimer;

  @override
  SpeechState build() {
    _speechToText = SpeechToText();
    _initSpeech();

    // Cleanup on dispose
    ref.onDispose(() {
      _silenceTimer?.cancel();
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
      listenMode: ListenMode.confirmation,
      partialResults: true,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      cancelOnError: true,
    );

    _startSilenceTimer();
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    print('Speech result (${state.localeId}): ${result.recognizedWords}');
    _resetSilenceTimer();
    state = state.copyWith(recognizedText: result.recognizedWords);
    if (result.finalResult) stopListening();
  }

  void _startSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(const Duration(seconds: 5), () => stopListening());
  }

  void _resetSilenceTimer() {
    _silenceTimer?.cancel();
    _startSilenceTimer();
  }

  Future<void> stopListening() async {
    _silenceTimer?.cancel();
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

/// Riverpod Provider
final speechProvider = NotifierProvider<SpeechNotifier, SpeechState>(
  () => SpeechNotifier(),
);
