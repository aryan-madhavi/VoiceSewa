import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/call_state.dart';
import '../providers/call_providers.dart';

class OutgoingCallScreen extends ConsumerWidget {
  const OutgoingCallScreen({super.key, required this.phase});

  final OutgoingPhase phase;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                'Calling…',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                phase.receiverUid,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 48),
              FloatingActionButton.large(
                backgroundColor: Colors.red,
                onPressed: () =>
                    ref.read(callControllerProvider.notifier).endCall(),
                child: const Icon(Icons.call_end, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
