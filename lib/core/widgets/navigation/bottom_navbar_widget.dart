import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/app/routes.dart';
import 'package:voicesewa_client/core/constants/app_constants.dart';
import 'package:voicesewa_client/core/providers/navbar_page_provider.dart';
import 'package:voicesewa_client/features/voicebot/providers/voicechat_provder.dart';

import '../../extensions/context_extensions.dart';

class BottomNavBar extends ConsumerWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(navTabProvider);
    final tabNotifier = ref.read(navTabProvider.notifier);
    final isProcessing = ref.watch(voiceBotControllerProvider);

    return NavigationBar(
      selectedIndex: currentTab.index,
      onDestinationSelected: (index) =>
          tabNotifier.setTab(NavTab.values[index]),
      destinations: AppConstants.pages(context).entries.map((entry) {
        final icon = entry.value[0] as Widget;
        final label = entry.value[1] as String;
        return label != context.loc.voiceBotTitle
            ? NavigationDestination(icon: icon, label: label)
            : FloatingActionButton(
                tooltip: 'Speak',
                backgroundColor: isProcessing
                    ? Colors.grey.shade300
                    : Theme.of(context).colorScheme.primaryContainer,
                onPressed: isProcessing
                    ? null
                    : () => Navigator.pushNamed(context, RoutePaths.voicebot),
                child: Icon(
                  isProcessing
                      ? Icons.hourglass_top_rounded
                      : Icons.mic_outlined,
                ),
              );
      }).toList(),
    );
  }
}
