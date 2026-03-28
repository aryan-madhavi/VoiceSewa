import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/app_contact.dart';

// Website Url 
const _websiteUrl = 
    'https://aryan-madhavi.github.io/Vaani/';

// Download links shown in the invite message.
const _androidUrl =
    'https://github.com/aryan-madhavi/Vaani/releases/latest/download/vaani.apk';

// Replace with TestFlight link once available.
// const _iosUrl = 'https://testflight.apple.com/join/XXXXXXXX';

const _inviteText =
    "Hey! I'm using Vaani for real-time voice translation on calls — "
    "it translates both sides of the call live so we can speak in our own languages.\n\n"
    "🌐 Website: $_websiteUrl\n\n"
    "📱 Android: $_androidUrl\n"
    "🍎 iOS: coming soon";

class ContactTile extends StatelessWidget {
  const ContactTile({
    super.key,
    required this.contact,
    required this.onCall,
  });

  final AppContact contact;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: contact.isOnApp ? cs.primary : Colors.grey.shade300,
        child: Text(
          contact.displayName.isNotEmpty
              ? contact.displayName[0].toUpperCase()
              : '?',
          style: TextStyle(
            color: contact.isOnApp ? cs.onPrimary : Colors.grey.shade700,
          ),
        ),
      ),
      title: Text(contact.displayName),
      subtitle: Text(
        contact.isOnApp ? 'On Vaani' : (contact.phoneNumber ?? ''),
        style: TextStyle(
          color: contact.isOnApp ? cs.primary : null,
          fontSize: 12,
        ),
      ),
      trailing: contact.isOnApp
          ? IconButton(
              icon: const Icon(Icons.call),
              color: cs.primary,
              tooltip: 'Translate call',
              onPressed: onCall,
            )
          : TextButton(
              onPressed: () => _showInviteSheet(context),
              child: const Text('Invite'),
            ),
    );
  }

  void _showInviteSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Text(
              'Invite ${contact.displayName}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(Icons.sms, color: Colors.white, size: 20),
              ),
              title: const Text('SMS'),
              onTap: () {
                Navigator.pop(context);
                _sendSms(contact.phoneNumber);
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.grey,
                child: Icon(Icons.share, color: Colors.white, size: 20),
              ),
              title: const Text('More…'),
              onTap: () {
                Navigator.pop(context);
                Share.share(_inviteText);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _sendSms(String? phone) async {
    if (phone == null) return;
    final encoded = Uri.encodeComponent(_inviteText);
    final uri = Uri.parse('sms:$phone?body=$encoded');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}
