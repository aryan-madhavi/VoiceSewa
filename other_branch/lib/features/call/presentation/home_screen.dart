import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/data/auth_repository.dart';
import '../../settings/data/language_repository.dart';
import '../../../core/constants.dart';
import '../providers/call_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _uidCtrl = TextEditingController();
  bool _calling = false;

  @override
  void dispose() {
    _uidCtrl.dispose();
    super.dispose();
  }

  Future<void> _call() async {
    final uid = _uidCtrl.text.trim();
    if (uid.isEmpty) return;
    setState(() => _calling = true);
    try {
      await ref.read(callControllerProvider.notifier).startCall(uid);
    } finally {
      setState(() => _calling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final settingsAsync = ref.watch(languageSettingsProvider);

    final lang = settingsAsync.valueOrNull?.lang ?? '…';
    final langName = kSupportedLanguages
        .firstWhere((l) => l.code == lang, orElse: () => kSupportedLanguages.first)
        .name;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Call Translate'),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            tooltip: 'My language',
            onPressed: () => context.push('/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            userAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (user) => Text(
                'Signed in as ${user?.email ?? '—'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'My language: $langName ($lang)',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            Text(
              'Start a Call',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _uidCtrl,
              decoration: const InputDecoration(
                labelText: 'Recipient Firebase UID',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _calling ? null : _call,
              icon: _calling
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.call),
              label: const Text('Call'),
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your UID',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    userAsync.when(
                      loading: () => const CircularProgressIndicator(),
                      error: (_, __) => const Text('—'),
                      data: (user) => SelectableText(
                        user?.uid ?? '—',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
