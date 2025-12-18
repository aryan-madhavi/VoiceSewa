import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/core/constants/app_constants.dart';
import 'package:voicesewa_client/core/constants/string_constants.dart';
import 'package:voicesewa_client/core/providers/navbar_page_provider.dart';
import 'package:voicesewa_client/features/voicebot/presentation/widgets/speech_overlay.dart';
import 'package:voicesewa_client/features/voicebot/providers/speech_provider.dart';

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
        return label != StringConstants.voiceBotTitle
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
                  
                  // Start listening
                  await speechNotifier.startListening();
                  
                  // Show overlay in the new context
                  showSpeechOverlay(context); 
                },
                child: Icon(
                  speechState.isListening ? Icons.mic : Icons.mic_outlined,
                ),
              );
      }).toList(),
    );
  }

  void showSpeechOverlay(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Speech Overlay',
      barrierColor: Colors.black.withOpacity(0.2),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const SpeechOverlayModal(),
      transitionBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.1),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
    );
  }
}
