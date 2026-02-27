import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_worker/features/voicebot/models/chat_message.dart';
import 'package:voicesewa_worker/features/voicebot/providers/chat_provider.dart';
import 'package:voicesewa_worker/features/voicebot/providers/speech_provider.dart';
import 'package:voicesewa_worker/features/voicebot/providers/voicechat_provder.dart';

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

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatControllerProvider);
    final isProcessing = ref.watch(voiceBotControllerProvider);

    // Auto-scroll to bottom
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
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _Header(
                  onClick: () async {
                    await ref.read(speechProvider.notifier).startListening();
                  },
                  onClose: () => Navigator.pop(context)),
                const Divider(height: 1),
                Expanded(
                  child: messages.isEmpty
                      ? const _EmptyState()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(12),
                          itemCount: messages.length,
                          itemBuilder: (_, index) {
                            final msg = messages[index];
                            return _ChatBubble(message: msg);
                          },
                        ),
                ),
                if (isProcessing) const _TypingIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.text,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onClose, onClick;

  const _Header({required this.onClose, required this.onClick});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.graphic_eq),
          const SizedBox(width: 8),
          const Text('Voice Assistant'),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.mic),
            onPressed: onClick,
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: const [
          SizedBox(width: 12),
          CircularProgressIndicator(strokeWidth: 2),
          SizedBox(width: 12),
          Text('Assistant is responding...'),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Say something to start the conversation'),
    );
  }
}
