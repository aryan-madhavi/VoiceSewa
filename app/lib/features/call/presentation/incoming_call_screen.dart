import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/call_state.dart';
import '../providers/call_providers.dart';

class IncomingCallScreen extends ConsumerWidget {
  const IncomingCallScreen({super.key, required this.signal});

  final CallSignal signal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(callControllerProvider.notifier);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 56,
                child: Icon(Icons.person, size: 56),
              ),
              const SizedBox(height: 24),
              Text(
                'Incoming Call',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                signal.callerUid,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Their language: ${signal.callerLang}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Decline
                  Column(
                    children: [
                      FloatingActionButton.large(
                        heroTag: 'decline',
                        backgroundColor: Colors.red,
                        onPressed: () => controller.declineCall(signal.sessionId),
                        child: const Icon(Icons.call_end, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      const Text('Decline'),
                    ],
                  ),
                  // Accept
                  Column(
                    children: [
                      FloatingActionButton.large(
                        heroTag: 'accept',
                        backgroundColor: Colors.green,
                        onPressed: () => controller.acceptCall(signal),
                        child: const Icon(Icons.call, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      const Text('Accept'),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
