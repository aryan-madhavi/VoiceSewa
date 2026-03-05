// lib/features/translate_call/presentation/call_history_screen.dart
//
// Displays the current user's 50 most recent calls.
// Swipe-to-delete removes the entry from the user's subcollection only —
// the other participant's history is untouched.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions.dart';
import '../../../../core/theme.dart';
import '../application/providers.dart';
import '../domain/call_history_entry.dart';
import '../domain/call_language.dart';
import '../domain/call_session.dart';

class CallHistoryScreen extends ConsumerWidget {
  const CallHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(callHistoryControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Call History'),
        centerTitle: true,
        elevation: 0,
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Error: $e')),
        data:    (entries) => entries.isEmpty
            ? const _EmptyState()
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount:       entries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder:     (_, i) =>
                    _HistoryTile(entry: entries[i]),
              ),
      ),
    );
  }
}

// ── History tile ──────────────────────────────────────────────────────────────

class _HistoryTile extends ConsumerWidget {
  const _HistoryTile({required this.entry});
  final CallHistoryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme      = Theme.of(context);
    final isOutgoing = entry.direction == CallDirection.outgoing;
    final isMissed   = entry.status == CallStatus.missed ||
                       entry.status == CallStatus.declined;

    final myLang    = CallLanguage.fromSourceLang(entry.myLang);
    final otherLang = CallLanguage.fromSourceLang(entry.otherLang);

    // Colour scheme for the direction icon
    final iconColor = isMissed
        ? AppTheme.danger
        : isOutgoing
            ? theme.colorScheme.primary
            : AppTheme.success;

    final iconBg = iconColor.withOpacity(0.12);

    final directionIcon = isMissed
        ? Icons.call_missed_rounded
        : isOutgoing
            ? Icons.call_made_rounded
            : Icons.call_received_rounded;

    return Dismissible(
      key: Key(entry.sessionId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.danger.withOpacity(0.85),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 24),
      ),
      onDismissed: (_) => ref
          .read(callHistoryControllerProvider.notifier)
          .deleteEntry(entry.sessionId),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            // Direction icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(directionIcon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),

            // Name + language pair
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.otherName,
                    style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${myLang.flag} ${myLang.nativeLabel}'
                    '  →  '
                    '${otherLang.flag} ${otherLang.nativeLabel}',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),

            // Date + duration
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatDate(entry.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Text(
                  isMissed
                      ? entry.status.name
                      : entry.durationSeconds != null
                          ? Duration(seconds: entry.durationSeconds!)
                              .toCallDuration()
                          : '—',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isMissed ? AppTheme.danger : null,
                    fontWeight:
                        isMissed ? FontWeight.w600 : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now  = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      return '${dt.hour.toString().padLeft(2, '0')}:'
             '${dt.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dt.weekday - 1];
    } else {
      return '${dt.day}/${dt.month}';
    }
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.call_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.35),
          ),
          const SizedBox(height: 16),
          Text('No calls yet',
              style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          Text(
            'Your translated calls will appear here.',
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.65)),
          ),
        ],
      ),
    );
  }
}