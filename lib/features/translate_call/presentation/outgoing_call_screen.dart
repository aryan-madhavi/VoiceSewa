// lib/features/translate_call/presentation/outgoing_call_screen.dart
//
// Shown to the caller while waiting for the receiver to accept.
// Animated ellipsis indicates ringing state.
// Single action: cancel the call.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme.dart';
import '../application/providers.dart';

class OutgoingCallScreen extends ConsumerStatefulWidget {
  const OutgoingCallScreen({super.key});

  @override
  ConsumerState<OutgoingCallScreen> createState() =>
      _OutgoingCallScreenState();
}

class _OutgoingCallScreenState extends ConsumerState<OutgoingCallScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dots;

  @override
  void initState() {
    super.initState();
    _dots = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _dots.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(callControllerProvider).valueOrNull?.session;

    return Scaffold(
      backgroundColor: AppTheme.callBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(),

              // ── Animated "Calling…" label ─────────────────────────────────
              AnimatedBuilder(
                animation: _dots,
                builder: (_, __) {
                  final count = (_dots.value * 4).floor().clamp(1, 3);
                  return Text(
                    'Calling${'.' * count}',
                    style: const TextStyle(
                      color: AppTheme.callTextSecondary,
                      fontSize: 18,
                      letterSpacing: 0.8,
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),

              // ── Avatar ────────────────────────────────────────────────────
              _StaticAvatar(
                name: session?.receiverName ?? '',
              ),
              const SizedBox(height: 22),

              // ── Receiver name ─────────────────────────────────────────────
              Text(
                session?.receiverName ?? '…',
                style: Theme.of(context).textTheme.callName,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              Text(
                'Waiting for answer…',
                style: TextStyle(
                    color: AppTheme.callTextSecondary.withOpacity(0.7),
                    fontSize: 14),
              ),
              const SizedBox(height: 20),

              // ── Translation badge ─────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.translate,
                        color: AppTheme.statusActive, size: 15),
                    const SizedBox(width: 6),
                    Text(
                      'Auto-translation ready',
                      style: TextStyle(
                          color: AppTheme.statusActive, fontSize: 13),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // ── Cancel ────────────────────────────────────────────────────
              Column(
                children: [
                  GestureDetector(
                    onTap: () =>
                        ref.read(callControllerProvider.notifier).hangUp(),
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: AppTheme.danger,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.danger.withOpacity(0.4),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.call_end_rounded,
                          color: Colors.white, size: 30),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Cancel',
                      style: TextStyle(
                          color: AppTheme.callTextSecondary, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 52),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaticAvatar extends StatelessWidget {
  const _StaticAvatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.primary.withOpacity(0.15),
        border: Border.all(
            color: AppTheme.primary.withOpacity(0.3), width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: AppTheme.callTextPrimary,
          fontSize: 38,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}