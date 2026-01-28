class AudioState {
  final bool isSpeaking;
  final String? error;

  const AudioState({
    this.isSpeaking = false,
    this.error,
  });

  AudioState copyWith({
    bool? isSpeaking,
    String? error,
  }) {
    return AudioState(
      isSpeaking: isSpeaking ?? this.isSpeaking,
      error: error,
    );
  }
}
