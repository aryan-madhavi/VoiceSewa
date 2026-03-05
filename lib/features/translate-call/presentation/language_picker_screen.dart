// lib/features/translate_call/presentation/language_picker_screen.dart
//
// Shown before a call is initiated so the user can confirm which
// language they speak. Also reachable from the home screen's
// language-selector strip to change the preference mid-session.
//
// Navigation is the caller's responsibility via the [onConfirmed] callback —
// this screen never calls go_router directly, keeping it portable.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/providers.dart';
import '../domain/call_language.dart';

class LanguagePickerScreen extends ConsumerWidget {
  const LanguagePickerScreen({
    super.key,
    required this.onConfirmed,
  });

  /// Called with the chosen [CallLanguage] when the user taps Continue.
  final void Function(CallLanguage language) onConfirmed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedLanguageProvider);
    final theme    = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Language'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          ColoredBox(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.35),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Which language do you speak?',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your speech will be translated in real time for the other caller.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Language list ─────────────────────────────────────────────────
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              itemCount: CallLanguage.values.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, index) {
                final lang = CallLanguage.values[index];
                return _LanguageTile(
                  language:   lang,
                  isSelected: lang == selected,
                  onTap: () => ref
                      .read(selectedLanguageProvider.notifier)
                      .state = lang,
                );
              },
            ),
          ),

          // ── Continue button ───────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: FilledButton(
                onPressed: () => onConfirmed(selected),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                child: Text('Continue with ${selected.nativeLabel}'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Language tile ─────────────────────────────────────────────────────────────

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  final CallLanguage language;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surface,
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Flag
            Text(language.flag, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 14),

            // Labels
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    language.nativeLabel,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    language.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer.withOpacity(0.7)
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Check
            if (isSelected)
              Icon(Icons.check_circle_rounded,
                  color: theme.colorScheme.primary, size: 22),
          ],
        ),
      ),
    );
  }
}