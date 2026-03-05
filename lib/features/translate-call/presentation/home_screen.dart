// lib/features/translate_call/presentation/home_screen.dart
//
// Contact list + language selector strip.
// Tapping the call button on a contact goes straight to initiateCall()
// using the language already selected in selectedLanguageProvider.
//
// _mockContacts is a placeholder — replace with a real Firestore
// users query when integrating into the main VoiceSewa app.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme.dart';
import '../application/providers.dart';
import '../domain/call_language.dart';

// ── Mock contact model ────────────────────────────────────────────────────────

class _Contact {
  const _Contact({
    required this.uid,
    required this.name,
    required this.language,
    required this.fcmToken,
  });

  final String uid;
  final String name;
  final CallLanguage language;
  final String fcmToken;
}

// Replace these with a real Firestore query in your app
const _mockContacts = [
  _Contact(
    uid:      'uid-ravi',
    name:     'Ravi Kumar',
    language: CallLanguage.hindi,
    fcmToken: 'REPLACE_WITH_REAL_FCM_TOKEN',
  ),
  _Contact(
    uid:      'uid-priya',
    name:     'Priya Menon',
    language: CallLanguage.malayalam,
    fcmToken: 'REPLACE_WITH_REAL_FCM_TOKEN',
  ),
  _Contact(
    uid:      'uid-arjun',
    name:     'Arjun Patel',
    language: CallLanguage.gujarati,
    fcmToken: 'REPLACE_WITH_REAL_FCM_TOKEN',
  ),
  _Contact(
    uid:      'uid-meera',
    name:     'Meera Nair',
    language: CallLanguage.tamil,
    fcmToken: 'REPLACE_WITH_REAL_FCM_TOKEN',
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myLanguage = ref.watch(selectedLanguageProvider);
    final theme      = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('VoiceSewa Translate'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Call history',
            onPressed: () => context.push('/history'),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
            onPressed: () =>
                ref.read(firebaseAuthProvider).signOut(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Language selector strip ────────────────────────────────────
          _LanguageStrip(
            selected: myLanguage,
            onTap: () => _showLanguageSheet(context, ref),
          ),

          // ── Section label ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: Text(
              'CONTACTS',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
          ),

          // ── Contact list ───────────────────────────────────────────────
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount:        _mockContacts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder:      (_, i) => _ContactTile(
                contact:    _mockContacts[i],
                myLanguage: myLanguage,
                onCall:     () => _call(context, ref,
                    _mockContacts[i], myLanguage),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Language bottom sheet ──────────────────────────────────────────────────

  void _showLanguageSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand:           false,
        initialChildSize: 0.65,
        maxChildSize:     0.92,
        builder: (_, controller) => Consumer(
          builder: (ctx, ref, __) {
            final selected = ref.watch(selectedLanguageProvider);
            return ListView.separated(
              controller:       controller,
              padding:          const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount:        CallLanguage.values.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 56),
              itemBuilder: (_, i) {
                final lang = CallLanguage.values[i];
                final isSelected = lang == selected;
                return ListTile(
                  leading: Text(lang.flag,
                      style: const TextStyle(fontSize: 24)),
                  title:   Text(lang.nativeLabel),
                  subtitle: Text(lang.label),
                  trailing: isSelected
                      ? Icon(Icons.check_circle_rounded,
                            color: Theme.of(ctx).colorScheme.primary)
                      : null,
                  onTap: () {
                    ref.read(selectedLanguageProvider.notifier).state =
                        lang;
                    Navigator.pop(ctx);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  // ── Initiate call ──────────────────────────────────────────────────────────

  Future<void> _call(
    BuildContext context,
    WidgetRef ref,
    _Contact contact,
    CallLanguage myLanguage,
  ) async {
    await ref.read(callControllerProvider.notifier).initiateCall(
          receiverUid:      contact.uid,
          receiverName:     contact.name,
          receiverFcmToken: contact.fcmToken,
          myLanguage:       myLanguage,
          partnerLanguage:  contact.language,
        );
    // Router redirect handles navigation to outgoing call screen
  }
}

// ── Language strip ────────────────────────────────────────────────────────────

class _LanguageStrip extends StatelessWidget {
  const _LanguageStrip({required this.selected, required this.onTap});
  final CallLanguage selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Row(
          children: [
            Text(
              'Your language:',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(selected.flag,
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      selected.nativeLabel,
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_drop_down_rounded,
                        color: theme.colorScheme.onPrimaryContainer,
                        size: 18),
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

// ── Contact tile ──────────────────────────────────────────────────────────────

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.contact,
    required this.myLanguage,
    required this.onCall,
  });

  final _Contact contact;
  final CallLanguage myLanguage;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              contact.name[0].toUpperCase(),
              style: TextStyle(
                color:      theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
                fontSize:   16,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Name + language
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '${contact.language.flag} ${contact.language.nativeLabel}',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),

          // Translation arrow preview
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '${myLanguage.flag}→${contact.language.flag}',
              style: const TextStyle(fontSize: 18),
            ),
          ),

          // Call button
          IconButton.filled(
            onPressed: onCall,
            icon: const Icon(Icons.call_rounded),
            tooltip: 'Call ${contact.name}',
          ),
        ],
      ),
    );
  }
}