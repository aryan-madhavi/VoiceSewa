import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/features/voicebot/providers/speech_to_text_provider.dart';

class SpeechOverlayModal extends ConsumerStatefulWidget {
  const SpeechOverlayModal({super.key});

  @override
  ConsumerState<SpeechOverlayModal> createState() =>
      _SpeechOverlayModalState();
}

class _SpeechOverlayModalState extends ConsumerState<SpeechOverlayModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.8,
      upperBound: 1.2,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final speechState = ref.watch(speechProvider);

    // Start / stop mic pulse
    if (speechState.isListening) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.value = 1.0;
    }

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Material(
          color: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: speechState.isListening
                    ? [Colors.red.shade400, Colors.red.shade600]
                    : [Colors.blue.shade400, Colors.blue.shade600],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                  color: (speechState.isListening
                          ? Colors.red
                          : Colors.blue)
                      .withOpacity(0.4),
                ),
              ],
            ),
            child: _OverlayContent(
              pulseController: _pulseController,
            ),
          ),
        ),
      ),
    );
  }
}

class _OverlayContent extends ConsumerWidget {
  final AnimationController pulseController;

  const _OverlayContent({
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speechState = ref.watch(speechProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Header
        Row(
          children: [
            /// Pulsing mic
            ScaleTransition(
              scale: pulseController,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mic,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(width: 12),

            /// Title
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    speechState.isListening
                        ? 'Listening'
                        : 'Voice Recognition',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (speechState.isListening)
                    const Text(
                      'Speak now - Release to stop',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),

            /// Close
            if (!speechState.isListening &&
                speechState.recognizedText.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close,
                    color: Colors.white, size: 20),
                onPressed: () {
                  ref.read(speechProvider.notifier).clearText();
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),

        const SizedBox(height: 12),

        /// Text box
        Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              speechState.recognizedText.isEmpty
                  ? (speechState.isListening
                      ? 'Start speaking...'
                      : 'No text recognized')
                  : speechState.recognizedText,
              key: ValueKey(speechState.recognizedText),
              style: TextStyle(
                fontSize: 18,
                height: 1.5,
                color: speechState.recognizedText.isEmpty
                    ? Colors.grey.shade400
                    : Colors.black87,
              ),
            ),
          ),
        ),

        /// Error
        if (speechState.error != null) ...[
          const SizedBox(height: 8),
          Text(
            speechState.error!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}
