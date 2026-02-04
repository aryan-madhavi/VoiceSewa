import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_worker/core/constants/app_constants.dart';
import '../../extensions/context_extensions.dart';
import '../../providers/language_provider.dart';

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
          tooltip: context.loc.selectLanguage, //'Select Language',
          onSelected: (String languageCode) {
            ref.read(localeProvider.notifier).changeLanguage(languageCode);
          },
          itemBuilder: (BuildContext context) => AppConstants.supportedLanguages
              .map(
                (language) => PopupMenuItem<String>(
                  value: language.code,
                  child: Text(language.displayName),
                ),
              )
              .toList(),
          // <PopupMenuEntry<String>>[
          // PopupMenuItem<String>(
          //   value: 'en',
          //     child: Text(
          //         "English" //"🇺🇸 English"
          //     ),
          // ),
          // const PopupMenuItem<String>(
          //   value: 'hi',
          //   child: Text('हिंदी'),
          // ),
          // const PopupMenuItem<String>(
          //    value: 'mr',
          //    child: Text('मराठी'),
          // ),
          // const PopupMenuItem<String>(
          //   value: 'gu',
          //   child: Text('ગુજરાતી'),
          // ),
          // ],
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
