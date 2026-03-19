import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/app_contact.dart';

final contactsProvider = FutureProvider<List<AppContact>>((ref) async {
  final granted = await FlutterContacts.requestPermission(readonly: true);
  if (!granted) return [];

  final raw = await FlutterContacts.getContacts(withProperties: true);

  // Collect unique normalised phone numbers for the batch lookup.
  final phoneSet = <String>{};
  for (final c in raw) {
    for (final p in c.phones) {
      try {
        phoneSet.add(toE164(p.number));
      } catch (_) {}
    }
  }

  // Single round-trip per registered number (parallel reads on phone_index).
  final registered =
      await ref.read(authRepositoryProvider).lookupUidsByPhones(phoneSet.toList());

  final contacts = raw.map((c) {
    String? firstPhone;
    try {
      if (c.phones.isNotEmpty) firstPhone = toE164(c.phones.first.number);
    } catch (_) {}
    final uid = firstPhone != null ? registered[firstPhone] : null;
    return AppContact(
      displayName: c.displayName,
      phoneNumber: firstPhone,
      uid: uid,
      isOnApp: uid != null,
    );
  }).toList();

  // Registered users first, then alphabetically within each group.
  contacts.sort((a, b) {
    if (a.isOnApp && !b.isOnApp) return -1;
    if (!a.isOnApp && b.isOnApp) return 1;
    return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
  });

  return contacts;
});
