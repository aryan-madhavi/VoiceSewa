import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_worker/constants/core/app_constants.dart';
import 'package:voicesewa_worker/providers/navbar_page_provider.dart';

import '../../extensions/context_extensions.dart';

class BottomNavBar extends ConsumerWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(navTabProvider);
    final tabNotifier = ref.read(navTabProvider.notifier);

    return NavigationBar(
      selectedIndex: currentTab.index,
      onDestinationSelected: (index) {
        tabNotifier.setTab(NavTab.values[index]);
      },
      destinations: AppConstants.getPages(context).entries.map((entry) {
        final icon = entry.value[0] as Widget;
        final label = entry.value[1] as String;
        return (label != '')
            ? NavigationDestination(icon: icon, label: label)
            : FloatingActionButton(
                onPressed: () {},
                tooltip: context.loc.speak, //'Speak',
                child: const Icon(Icons.mic),
              );
      }).toList(),
    );
  }
}