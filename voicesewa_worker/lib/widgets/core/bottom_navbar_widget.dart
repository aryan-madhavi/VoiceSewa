import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_worker/constants/core/app_constants.dart';
import 'package:voicesewa_worker/providers/navbar_page_provider.dart';

class BottomNavBar extends ConsumerWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(navTabProvider);
    final tabNotifier = ref.read(navTabProvider.notifier);

    return Stack(
      alignment: Alignment.center,
      children: [
        NavigationBar(
          selectedIndex: currentTab.index,
          onDestinationSelected: (index) {
            tabNotifier.setTab(NavTab.values[index]);
          },
          destinations: AppConstants.pages.entries.map((entry) {
            final icon = entry.value[0] as Widget;
            final label = entry.value[1] as String;
            return NavigationDestination(
              icon: icon,
              label: label,
            );
          }).toList(),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FloatingActionButton(
              elevation: 4,
              shape: const CircleBorder(),
              onPressed: () {},
              tooltip: 'Speak',
              child: const Icon(Icons.mic),
            ),
          ],
        ),
      ],
    );
  }
}