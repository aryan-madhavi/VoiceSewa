import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../data/language_repository.dart';
import '../../auth/data/auth_repository.dart';

class LanguageSettingsScreen extends ConsumerWidget {
  /// When true, shows an onboarding header and a "Continue" button instead
  /// of the standard AppBar back arrow.  Called from /onboarding after
  /// first sign-in.
  const LanguageSettingsScreen({super.key, this.isOnboarding = false});

  final bool isOnboarding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(languageSettingsProvider);

    return Scaffold(
      appBar: isOnboarding
          ? null // no back arrow during onboarding
          : AppBar(title: const Text('My Language')),
      body: Column(
        children: [
          if (isOnboarding) ...[
            const SizedBox(height: 48),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Icon(Icons.translate_rounded,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(
                    'What language do you speak?',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pick once — Vaani remembers it for every call.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: .6),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          Expanded(
            child: settingsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (settings) => ListView.builder(
                itemCount: kSupportedLanguages.length,
                itemBuilder: (context, i) {
                  final option = kSupportedLanguages[i];
                  final selected = option.code == settings.lang;
                  return ListTile(
                    title: Text(option.name),
                    subtitle: Text(option.nativeName),
                    trailing: selected
                        ? Icon(Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary)
                        : null,
                    onTap: () => ref
                        .read(languageSettingsProvider.notifier)
                        .setLang(option.code),
                  );
                },
              ),
            ),
          ),
          if (isOnboarding) ...[
            Padding(
              padding: const EdgeInsets.all(24),
              child: FilledButton(
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52)),
                onPressed: () async {
                  final user =
                      await ref.read(currentUserProvider.future);
                  if (user != null) {
                    await ref
                        .read(authRepositoryProvider)
                        .markOnboarded(user.uid);
                    // Invalidate currentUserProvider so the router picks up
                    // the updated isOnboarded=true from Firestore.
                    ref.invalidate(currentUserProvider);
                  }
                  if (context.mounted) context.go('/');
                },
                child: const Text('Continue'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
