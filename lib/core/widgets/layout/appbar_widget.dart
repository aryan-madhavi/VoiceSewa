import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/core/extensions/context_extensions.dart';
import 'package:voicesewa_client/core/providers/language_provider.dart';
import 'package:voicesewa_client/features/voicebot/providers/speech_provider.dart';

class AppBarWidget extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  const AppBarWidget({
    super.key, 
    required this.title
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      title: Text(title),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.translate),
          tooltip: context.loc.selectLanguage,  //'Select Language',
          onSelected: (String languageCode) {
            final Map defaultLocales = {
              'en': 'en_US',
              'hi': 'hi_IN',
              'mr': 'mr_IN',
              'gu': 'gu_IN',
            };
            ref.read(speechProvider.notifier).setLocale(defaultLocales[languageCode] ?? 'en_US');
            ref.read(localeProvider.notifier).changeLanguage(languageCode);
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'en',
                child: Text(
                    "English" //"🇺🇸 English"
                ),
            ),
            const PopupMenuItem<String>(
              value: 'hi',  
              child: Text('हिंदी'),
            ),
            const PopupMenuItem<String>(
               value: 'mr',
               child: Text('मराठी'),
            ),
            const PopupMenuItem<String>(
              value: 'gu',
              child: Text('ગુજરાતી'),
            ),
          ],
        )
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
