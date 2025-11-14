import 'package:flutter/material.dart';
import 'package:voicesewa_client/constants/core/app_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/providers/navbar_page_provider.dart';
import 'package:voicesewa_client/providers/speech_to_text_provider.dart';

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
      onDestinationSelected: (index) {
        tabNotifier.setTab(NavTab.values[index]);
      },
      destinations: AppConstants.pages.entries.map((entry) {
        final icon = entry.value[0] as Widget;
        final label = entry.value[1] as String;
        return (label != '')
            ? NavigationDestination(icon: icon, label: label)
            : NavigationDestination(
                icon: GestureDetector(
                  onLongPress: () async {
                    // Start listening on long press
                    print('Long press detected - starting listening');
                    await speechNotifier.startListening();
                  },
                  onLongPressEnd: (_) async {
                    // Stop listening when long press ends
                    print('Long press ended - stopping listening');
                    await speechNotifier.stopListening();
                  },
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: speechState.isListening 
                          ? Colors.red 
                          : Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: speechState.isListening ? [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ] : null,
                    ),
                    child: Icon(
                      speechState.isListening ? Icons.mic : Icons.mic_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                label: '',
              );
      }).toList(),
    );
  }
}