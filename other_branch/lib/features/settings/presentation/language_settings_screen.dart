import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../data/language_repository.dart';

class LanguageSettingsScreen extends ConsumerWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(languageSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Language')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
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
    );
  }
}
