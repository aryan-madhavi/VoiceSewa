class AudioState {
  final bool isSpeaking;
  final bool isRecording;
  final String? error;

  const AudioState({
    this.isSpeaking = false,
    this.isRecording = false,
    this.error,
  });

  AudioState copyWith({bool? isSpeaking, bool? isRecording, String? error}) {
    return AudioState(
      isSpeaking: isSpeaking ?? this.isSpeaking,
      isRecording: isRecording ?? this.isRecording,
      error: error,
    );
  }
}
