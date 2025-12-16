import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

// Speech State Model
class SpeechState {
  final bool isListening;
  final String recognizedText;
  final bool isInitialized;
  final String? error;

  SpeechState({
    this.isListening = false,
    this.recognizedText = '',
    this.isInitialized = false,
    this.error,
  });

  SpeechState copyWith({
    bool? isListening,
    String? recognizedText,
    bool? isInitialized,
    String? error,
  }) {
    return SpeechState(
      isListening: isListening ?? this.isListening,
      recognizedText: recognizedText ?? this.recognizedText,
      isInitialized: isInitialized ?? this.isInitialized,
      error: error,
    );
  }
}

// Speech Notifier using modern Riverpod Notifier
class SpeechNotifier extends Notifier<SpeechState> {
  late SpeechToText _speechToText;

  @override
  SpeechState build() {
    _speechToText = SpeechToText();
    _initSpeech();
    return SpeechState();
  }

  Future<void> _initSpeech() async {
    try {
      bool available = await _speechToText.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            state = state.copyWith(isListening: false);
          }
        },
        onError: (error) {
          state = state.copyWith(
            error: error.errorMsg,
            isListening: false,
          );
        },
      );
      state = state.copyWith(isInitialized: available);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to initialize speech recognition',
        isInitialized: false,
      );
    }
  }

  Future<void> startListening({String localeId = 'en_US'}) async {
    print('startListening called');
    
    if (!state.isInitialized) {
      print('Not initialized, initializing...');
      await _initSpeech();
    }

    if (!_speechToText.isAvailable) {
      print('Speech recognition not available');
      state = state.copyWith(error: 'Speech recognition not available');
      return;
    }

    // Clear previous text
    state = state.copyWith(
      recognizedText: '',
      error: null,
      isListening: true,
    );

    print('Starting to listen...');
    await _speechToText.listen(
      onResult: _onSpeechResult,
      localeId: localeId,
      listenMode: ListenMode.confirmation,
      pauseFor: Duration(seconds: 5),
      partialResults: true,
      cancelOnError: true,
      listenFor: Duration(seconds: 30),
    );

    print('Listen started successfully');
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    print('Speech result: ${result.recognizedWords}');
    state = state.copyWith(
      recognizedText: result.recognizedWords,
    );
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
    state = state.copyWith(isListening: false);
  }

  void clearText() {
    state = state.copyWith(
      recognizedText: '',
      error: null,
    );
  }
}

// Provider using modern NotifierProvider
final speechProvider = NotifierProvider<SpeechNotifier, SpeechState>(() {
  return SpeechNotifier();
});