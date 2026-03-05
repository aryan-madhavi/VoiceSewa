// lib/features/translate_call/presentation/home_screen.dart
//
// Contact list populated from Firestore users collection.
// All users (except self) are shown as callable contacts.
// The language strip reflects the user's stored preference and saves
// any changes back to their Firestore profile.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme.dart';
import '../../auth/domain/user_profile.dart';
import '../application/providers.dart';
import '../domain/call_language.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _languageInitialised = false;

  @override
  Widget build(BuildContext context) {
    final myLanguage   = ref.watch(selectedLanguageProvider);
    final usersAsync   = ref.watch(allUsersProvider);
    final profileAsync = ref.watch(currentUserProfileProvider);
    final theme        = Theme.of(context);

    // Sync selectedLanguageProvider with the user's stored preference
    // once the profile loads (only on first load, not on every rebuild)
    profileAsync.whenData((profile) {
      if (profile != null && !_languageInitialised) {
        _languageInitialised = true;
        final stored = CallLanguage.fromSourceLang(profile.language);
        if (stored != ref.read(selectedLanguageProvider)) {
          // Use addPostFrameCallback to avoid setState during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ref.read(selectedLanguageProvider.notifier).state = stored;
            }
          });
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('VoiceSewa Translate'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon:    const Icon(Icons.history_rounded),
            tooltip: 'Call history',
            onPressed: () => context.push('/history'),
          ),
          IconButton(
            icon:    const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
            onPressed: () => ref.read(firebaseAuthProvider).signOut(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Language selector strip ──────────────────────────────────────
          _LanguageStrip(
            selected: myLanguage,
            onTap:    () => _showLanguageSheet(context, ref),
          ),

          // ── Section label ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: Text(
              'CONTACTS',
              style: theme.textTheme.labelSmall?.copyWith(
                color:       theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
          ),

          // ── Contact list from Firestore ──────────────────────────────────
          Expanded(
            child: usersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:   (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Could not load contacts: $e',
                      textAlign: TextAlign.center),
                ),
              ),
              data: (users) {
                if (users.isEmpty) {
                  return const _EmptyContacts();
                }
                return ListView.separated(
                  padding:          const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount:        users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _ContactTile(
                    user:       users[i],
                    myLanguage: myLanguage,
                    onCall: () => _call(context, ref, users[i], myLanguage),
                  ),
                );
              },
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
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
              itemBuilder: (_, i) {
                final lang       = CallLanguage.values[i];
                final isSelected = lang == selected;
                return ListTile(
                  leading: Text(lang.flag,
                      style: const TextStyle(fontSize: 24)),
                  title:    Text(lang.nativeLabel),
                  subtitle: Text(lang.label),
                  trailing: isSelected
                      ? Icon(Icons.check_circle_rounded,
                            color: Theme.of(ctx).colorScheme.primary)
                      : null,
                  onTap: () {
                    ref.read(selectedLanguageProvider.notifier).state = lang;
                    // Persist the choice to Firestore
                    _saveLanguage(ref, lang);
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

  /// Persists the selected language to the current user's Firestore doc.
  void _saveLanguage(WidgetRef ref, CallLanguage lang) {
    final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
    if (uid == null) return;
    ref
        .read(translateCallRepositoryProvider)
        .updateUserLanguage(uid, lang.sourceLang);
  }

  // ── Initiate call ──────────────────────────────────────────────────────────

  Future<void> _call(
    BuildContext context,
    WidgetRef ref,
    UserProfile contact,
    CallLanguage myLanguage,
  ) async {
    final partnerLanguage = CallLanguage.fromSourceLang(contact.language);

    await ref.read(callControllerProvider.notifier).initiateCall(
          receiverUid:     contact.uid,
          receiverName:    contact.displayName,
          myLanguage:      myLanguage,
          partnerLanguage: partnerLanguage,
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
                  color:        theme.colorScheme.primaryContainer,
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
                        color:      theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                        fontSize:   14,
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
    required this.user,
    required this.myLanguage,
    required this.onCall,
  });

  final UserProfile  user;
  final CallLanguage myLanguage;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final theme           = Theme.of(context);
    final contactLanguage = CallLanguage.fromSourceLang(user.language);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color:        theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius:          22,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              user.displayName.isNotEmpty
                  ? user.displayName[0].toUpperCase()
                  : '?',
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
                  user.displayName,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '${contactLanguage.flag} ${contactLanguage.nativeLabel}',
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
              '${myLanguage.flag}→${contactLanguage.flag}',
              style: const TextStyle(fontSize: 18),
            ),
          ),

          // Call button — disabled if FCM token is missing (user never opened app)
          IconButton.filled(
            onPressed: user.fcmToken != null ? onCall : null,
            icon:      const Icon(Icons.call_rounded),
            tooltip:   user.fcmToken != null
                ? 'Call ${user.displayName}'
                : '${user.displayName} is not reachable',
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyContacts extends StatelessWidget {
  const _EmptyContacts();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size:  72,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.35),
            ),
            const SizedBox(height: 16),
            Text(
              'No other users yet',
              style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              'Other users will appear here once they sign up.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.65)),
            ),
          ],
        ),
      ),
    );
  }
}