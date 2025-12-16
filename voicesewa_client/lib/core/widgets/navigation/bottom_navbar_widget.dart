import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/core/constants/app_constants.dart';
import 'package:voicesewa_client/core/providers/navbar_page_provider.dart';
import 'package:voicesewa_client/core/providers/speech_to_text_provider.dart';

class BottomNavBar extends ConsumerWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(navTabProvider);
    final tabNotifier = ref.read(navTabProvider.notifier);
    final speechNotifier = ref.read(speechProvider.notifier);
    final speechState = ref.watch(speechProvider);

    return NavigationBar(
      selectedIndex: currentTab.index,
      onDestinationSelected: (index) =>
          tabNotifier.setTab(NavTab.values[index]),
      destinations: AppConstants.pages.entries.map((entry) {
        final icon = entry.value[0] as Widget;
        final label = entry.value[1] as String;
        return label.isNotEmpty
            ? NavigationDestination(icon: icon, label: label)
            : FloatingActionButton(
                tooltip: 'Speak',
                backgroundColor: speechState.isListening
                    ? Colors.red
                    : Theme.of(context).colorScheme.primaryContainer,
                onPressed: () async {
                  if (!speechState.isInitialized) {
                    // Show snackbar if speech is not initialized
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Speech recognition is not initialized yet.',
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }
                  await speechNotifier.startListening();
                },
                child: Icon(
                  speechState.isListening ? Icons.mic : Icons.mic_outlined,
                ),
              );
      }).toList(),
    );
  }
}
