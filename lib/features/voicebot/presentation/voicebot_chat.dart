import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/core/extensions/context_extensions.dart';
import 'package:voicesewa_client/features/voicebot/presentation/audio_bubble.dart';
import 'package:voicesewa_client/features/voicebot/providers/audio_provider.dart';
import 'package:voicesewa_client/features/voicebot/providers/chat_provider.dart';
import 'package:voicesewa_client/features/voicebot/providers/voicechat_provder.dart';

class VoiceBotPage extends ConsumerStatefulWidget {
  const VoiceBotPage({super.key});

  @override
  ConsumerState<VoiceBotPage> createState() => _VoiceBotPageState();
}

class _VoiceBotPageState extends ConsumerState<VoiceBotPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Listen to message list changes and scroll to bottom — not inside build()
    ref.listenManual(chatControllerProvider, (_, __) => _scrollToBottom());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
    final audioState = ref.watch(audioProvider);
    final isProcessing = ref.watch(voiceBotControllerProvider);
    final isRecording = audioState.isRecording;

    return Scaffold(
      appBar: AppBar(title: Text(context.loc.voiceAssistant), centerTitle: true),
      body: Column(
        children: [
          // ── Message list ──────────────────────────────────────────────
          Expanded(
            child: messages.isEmpty
                ? const _EmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (_, i) => AudioBubble(message: messages[i]),
                  ),
          ),

          // ── Typing indicator ──────────────────────────────────────────
          if (isProcessing) const _TypingIndicator(),

          // ── Bottom bar ────────────────────────────────────────────────
          _BottomBar(
            isRecording: isRecording,
            isProcessing: isProcessing,
            onMicPressed: _onMicPressed,
          ),
        ],
      ),
    );
  }
}

// ─── Bottom bar ──────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final bool isRecording;
  final bool isProcessing;
  final VoidCallback onMicPressed;

  const _BottomBar({
    required this.isRecording,
    required this.isProcessing,
    required this.onMicPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: isProcessing ? null : onMicPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isProcessing
                    ? Colors.grey.shade300
                    : isRecording
                    ? Colors.red.shade500
                    : colorScheme.primary,
                boxShadow: isRecording
                    ? [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.4),
                          blurRadius: 16,
                          spreadRadius: 4,
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isProcessing
                ? 'Processing...'
                : isRecording
                ? 'Tap to stop & send'
                : 'Tap to speak',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

// ─── Supporting widgets ───────────────────────────────────────────────────────

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(context.loc.assistantIsResponding),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.mic_none_rounded, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            context.loc.tapTheMicToStartTalking,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
