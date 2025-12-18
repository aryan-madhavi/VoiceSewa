import 'package:speech_to_text/speech_to_text.dart';

class SpeechState {
  final bool isListening;
  final String recognizedText;
  final bool isInitialized;
  final String? error;
  final String localeId;
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