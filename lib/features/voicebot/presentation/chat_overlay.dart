import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/core/extensions/context_extensions.dart';
import 'package:voicesewa_client/features/voicebot/presentation/audio_bubble.dart';
import 'package:voicesewa_client/features/voicebot/providers/audio_provider.dart';
import 'package:voicesewa_client/features/voicebot/providers/chat_provider.dart';
import 'package:voicesewa_client/features/voicebot/providers/voicechat_provder.dart';

class ChatOverlayModal extends ConsumerStatefulWidget {
  const ChatOverlayModal({super.key});

  @override
  ConsumerState<ChatOverlayModal> createState() => _ChatOverlayModalState();
}

class _ChatOverlayModalState extends ConsumerState<ChatOverlayModal> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onMicPressed() async {
    final audioNotifier = ref.read(audioProvider.notifier);
    final isRecording = ref.read(audioProvider).isRecording;

    if (isRecording) {
      final path = await audioNotifier.stopRecording();
      if (path != null) {
        await ref.read(voiceBotControllerProvider.notifier).processAudio(path);
      }
    } else {
      await audioNotifier.startRecording();
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatControllerProvider);
    final isProcessing = ref.watch(voiceBotControllerProvider);
    final isRecording = ref.watch(audioProvider).isRecording;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });

    return SafeArea(
      child: Material(
        color: Colors.transparent,
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            margin: const EdgeInsets.all(16),
            height: MediaQuery.of(context).size.height * 0.65,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                _OverlayHeader(
                  isRecording: isRecording,
                  isProcessing: isProcessing,
                  onMicTap: isProcessing ? null : _onMicPressed,
                  onClose: () => Navigator.pop(context),
                ),
                const Divider(height: 1),

                // Messages
                Expanded(
                  child: messages.isEmpty
                      ? Center(
                          child: Text(context.loc.tapTheMicToStartTalking),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(12),
                          itemCount: messages.length,
                          itemBuilder: (_, i) =>
                              AudioBubble(message: messages[i]),
                        ),
                ),

                // Typing indicator
                if (isProcessing)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                        Text(context.loc.assistantIsResponding),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OverlayHeader extends StatelessWidget {
  final bool isRecording;
  final bool isProcessing;
  final VoidCallback? onMicTap;
  final VoidCallback onClose;

  const _OverlayHeader({
    required this.isRecording,
    required this.isProcessing,
    required this.onMicTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.graphic_eq, color: isRecording ? Colors.red : null),
          const SizedBox(width: 8),
          Text(
            isRecording ? 'Recording...' : context.loc.voiceAssistant,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const Spacer(),
          // Mic toggle button
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isRecording
                  ? Colors.red.withOpacity(0.1)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                color: isRecording ? Colors.red : null,
              ),
              onPressed: onMicTap,
            ),
          ),
          IconButton(icon: const Icon(Icons.close), onPressed: onClose),
        ],
      ),
    );
  }
}
