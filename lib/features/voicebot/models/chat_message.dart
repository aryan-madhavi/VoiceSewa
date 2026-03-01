enum ChatRole { user, bot }

class ChatMessage {
  final ChatRole role;
  final String? text; // transcription or bot text response
  final String? audioPath; // local file path to the audio

  const ChatMessage({required this.role, this.text, this.audioPath});
}
