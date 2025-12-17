import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_worker/providers/language_provider.dart';

class AppBarWidget extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  const AppBarWidget({super.key, required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      title: Text(title),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.translate),
          tooltip: 'Select Language',
          onSelected: (String languageCode) {
            ref.read(localeProvider.notifier).changeLanguage(languageCode);
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'en',
                child: Text("🇺🇸 English"),
            ),
            const PopupMenuItem<String>(
              value: 'hi',  
              child: Text('🇮🇳 हिंदी (Hindi)'),
            ),
            const PopupMenuItem<String>(
               value: 'mr',
               child: Text('🇮🇳 मराठी (Marathi)'),
            ),
            const PopupMenuItem<String>(
              value: 'gu',
              child: Text('🇮🇳 ગુજરાતી (Gujarati)'),
            ),
          ],
        )
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
