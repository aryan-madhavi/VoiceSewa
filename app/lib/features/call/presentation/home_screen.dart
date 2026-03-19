import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:record/record.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../auth/data/auth_repository.dart';
import '../../settings/data/language_repository.dart';
import '../../../core/constants.dart';
import '../data/contacts_provider.dart';
import '../domain/app_contact.dart';
import '../providers/call_providers.dart';
import 'contact_tile.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _search = '';

  // ── Lifecycle ───────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _requestPermissions();
      await _storeFcmToken();
    });
  }

  Future<void> _requestPermissions() async {
    await AudioRecorder().hasPermission();
    await FlutterContacts.requestPermission(readonly: true);
    await FirebaseMessaging.instance.requestPermission();
  }

  Future<void> _storeFcmToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;
    await ref.read(authRepositoryProvider).updateFcmToken(user.uid, token);
    FirebaseMessaging.instance.onTokenRefresh.listen((t) {
      ref.read(authRepositoryProvider).updateFcmToken(user.uid, t);
    });
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  Future<void> _call(AppContact contact) async {
    if (contact.uid == null) return;
    try {
      await ref.read(callControllerProvider.notifier).startCall(contact.uid!);
      final phase = ref.read(callControllerProvider);
      if (phase.hasError && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Call failed: ${phase.error}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Call failed: $e')));
      }
    }
  }

  // ── UI ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final settingsAsync = ref.watch(languageSettingsProvider);
    final contactsAsync = ref.watch(contactsProvider);

    final lang = settingsAsync.valueOrNull?.lang ?? '…';
    final langName = kSupportedLanguages
        .firstWhere((l) => l.code == lang,
            orElse: () => kSupportedLanguages.first)
        .name;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vaani'),
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── User info header ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: userAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (user) => Text(
                '${user?.phoneNumber ?? ''}  ·  $langName',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ),

          // ── Search bar ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search contacts…',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
            ),
          ),

          // ── Contacts list ─────────────────────────────────────────────────
          Expanded(
            child: contactsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.contacts_outlined, size: 48),
                    const SizedBox(height: 12),
                    const Text('Could not load contacts'),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => ref.invalidate(contactsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (contacts) => _ContactsList(
                contacts: contacts,
                search: _search,
                onCall: _call,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Contacts list ──────────────────────────────────────────────────────────────

class _ContactsList extends StatelessWidget {
  const _ContactsList({
    required this.contacts,
    required this.search,
    required this.onCall,
  });

  final List<AppContact> contacts;
  final String search;
  final void Function(AppContact) onCall;

  @override
  Widget build(BuildContext context) {
    final filtered = search.isEmpty
        ? contacts
        : contacts
            .where((c) =>
                c.displayName.toLowerCase().contains(search) ||
                (c.phoneNumber?.contains(search) ?? false))
            .toList();

    final onApp = filtered.where((c) => c.isOnApp).toList();
    final notOnApp = filtered.where((c) => !c.isOnApp).toList();

    if (filtered.isEmpty) {
      return const Center(child: Text('No contacts found.'));
    }

    final items = <Object>[];
    if (onApp.isNotEmpty) {
      items.add('On Vaani (${onApp.length})');
      items.addAll(onApp);
    }
    if (notOnApp.isNotEmpty) {
      items.add('Invite to Vaani');
      items.addAll(notOnApp);
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        if (item is String) return _SectionHeader(item);
        final contact = item as AppContact;
        return ContactTile(
          contact: contact,
          onCall: () => onCall(contact),
        );
      },
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}
