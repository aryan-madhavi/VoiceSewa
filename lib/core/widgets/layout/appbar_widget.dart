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
            PopupMenuItem<String>(
              value: 'hi',  
              child: Text(context.loc.str_876667),
            ),
            PopupMenuItem<String>(
               value: 'mr',
               child: Text(context.loc.str_147662),
            ),
            PopupMenuItem<String>(
              value: 'gu',
              child: Text(context.loc.str_112163),
            ),
          ],
        )
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
