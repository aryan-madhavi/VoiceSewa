import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/call_repository.dart';
import '../domain/call_state.dart';
import '../providers/call_providers.dart';
import '../../settings/data/language_repository.dart';

class ActiveCallScreen extends ConsumerWidget {
  const ActiveCallScreen({super.key, required this.phase});

  final ActivePhase phase;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transcripts = ref.watch(transcriptsProvider);
    final myLang = ref.watch(languageSettingsProvider).valueOrNull?.lang ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('On Call'),
        automaticallyImplyLeading: false,
        actions: [
          // Speaker / earpiece toggle
          Builder(builder: (context) {
            final isSpeaker = ref.watch(speakerProvider);
            return IconButton(
              icon: Icon(isSpeaker ? Icons.volume_up : Icons.hearing),
              tooltip: isSpeaker ? 'Switch to earpiece' : 'Switch to speaker',
              onPressed: () async {
                final next = !isSpeaker;
                ref.read(speakerProvider.notifier).state = next;
                await ref.read(callRepositoryProvider).setSpeaker(next);
              },
            );
          }),
          IconButton(
            icon: const Icon(Icons.call_end, color: Colors.red),
            tooltip: 'End call',
            onPressed: () =>
                ref.read(callControllerProvider.notifier).endCall(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            color: Theme.of(context).colorScheme.primaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.mic, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Live translation active · Your language: $myLang',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          // Transcript list
          Expanded(
            child: transcripts.isEmpty
                ? Center(
                    child: Text(
                      'Start speaking…',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    reverse: true,
                    itemCount: transcripts.length,
                    itemBuilder: (context, i) {
                      final entry =
                          transcripts[transcripts.length - 1 - i];
                      return _TranscriptBubble(
                        entry: entry,
                        isMine: !entry.isTranslation,
                      );
                    },
                  ),
          ),
          // End call button (bottom bar)
          Padding(
            padding: const EdgeInsets.all(24),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: () =>
                  ref.read(callControllerProvider.notifier).endCall(),
              icon: const Icon(Icons.call_end),
              label: const Text('End Call'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TranscriptBubble extends StatelessWidget {
  const _TranscriptBubble({required this.entry, required this.isMine});

  final TranscriptEntry entry;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isTranslation = entry.isTranslation;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .75),
        decoration: BoxDecoration(
          color: isMine ? cs.primaryContainer : cs.secondaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isTranslation)
              Text(
                'Translated · ${entry.lang}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSecondaryContainer.withValues(alpha: .6),
                    ),
              ),
            Text(
              entry.text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle:
                        entry.isFinal ? FontStyle.normal : FontStyle.italic,
                    color: isMine ? cs.onPrimaryContainer : cs.onSecondaryContainer,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
