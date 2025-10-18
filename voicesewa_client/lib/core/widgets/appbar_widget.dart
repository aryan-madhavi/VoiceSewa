import 'package:flutter/material.dart';
import 'package:voicesewa_client/core/constants/string_constants.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  
  const AppBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      title: Text(StringConstants.appName),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
