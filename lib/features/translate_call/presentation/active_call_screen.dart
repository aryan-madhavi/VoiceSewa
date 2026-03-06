// lib/features/translate_call/presentation/active_call_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions.dart';
import '../../../../core/theme.dart';
import '../application/call_controller.dart';
import '../application/providers.dart';

class ActiveCallScreen extends ConsumerWidget {
  const ActiveCallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final call = ref.watch(callControllerProvider).valueOrNull
        ?? const CallState();

    final user        = ref.watch(firebaseAuthProvider).currentUser;
    final session     = call.session;

    // FIX (Bug 1 display): Determine partner name from the perspective of the
    // current user. Previously this always showed receiverName regardless of
    // which side of the call you were on, meaning the receiver saw their own
    // name as "partner".
    final String partnerName;
    if (session == null) {
      partnerName = '';
    } else if (session.callerUid == user?.uid) {
      // I am the caller → partner is the receiver
      partnerName = session.receiverName;
    } else {
      // I am the receiver → partner is the caller
      partnerName = session.callerName;
    }

    return Scaffold(
      backgroundColor: AppTheme.callBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              _TopBar(
                partnerName:  partnerName,
                callDuration: call.callDuration,
              ),
              const SizedBox(height: 24),
              _LangRow(
                myLanguage:      call.myLanguage,
                partnerLanguage: call.partnerLanguage,
                isMuted:         call.isMuted,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: _CaptionBox(
                        label:   'You',
                        text:    call.myTranscript,
                        isMuted: call.isMuted,
                        accent:  AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _CaptionBox(
                        label:   'Partner',
                        text:    call.partnerTranscript,
                        isMuted: false,
                        accent:  Colors.white24,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _ControlRow(
                isMuted: call.isMuted,
                onMute:  () =>
                    ref.read(callControllerProvider.notifier).toggleMute(),
                onEnd:   () =>
                    ref.read(callControllerProvider.notifier).hangUp(),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.partnerName, required this.callDuration});
  final String   partnerName;
  final Duration callDuration;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              partnerName,
              style: Theme.of(context).textTheme.callName
                  .copyWith(fontSize: 22),
            ),
            const SizedBox(height: 2),
            Text(
              callDuration.toCallDuration(),
              style: Theme.of(context).textTheme.callTimer,
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color:  AppTheme.statusActive.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppTheme.statusActive.withOpacity(0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7, height: 7,
                decoration: const BoxDecoration(
                  color: AppTheme.statusActive,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              const Text('Live',
                  style: TextStyle(
                      color: AppTheme.statusActive, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Language row ──────────────────────────────────────────────────────────────

class _LangRow extends StatelessWidget {
  const _LangRow({
    required this.myLanguage,
    required this.partnerLanguage,
    required this.isMuted,
  });
  final dynamic myLanguage;
  final dynamic partnerLanguage;
  final bool isMuted;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _LangCard(
            flag:     myLanguage?.flag ?? '',
            native:   myLanguage?.nativeLabel ?? '',
            sublabel: 'You',
            isMuted:  isMuted,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Icon(Icons.arrow_forward_rounded,
              color: Colors.white24, size: 18),
        ),
        Expanded(
          child: _LangCard(
            flag:     partnerLanguage?.flag ?? '',
            native:   partnerLanguage?.nativeLabel ?? '',
            sublabel: 'Partner',
            isMuted:  false,
          ),
        ),
      ],
    );
  }
}

class _LangCard extends StatelessWidget {
  const _LangCard({
    required this.flag,
    required this.native,
    required this.sublabel,
    required this.isMuted,
  });
  final String flag;
  final String native;
  final String sublabel;
  final bool isMuted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color:        Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: AppTheme.callBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 20)),
              if (isMuted) ...[
                const SizedBox(width: 6),
                const Icon(Icons.mic_off_rounded,
                    color: AppTheme.statusRinging, size: 14),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(native,
              style: const TextStyle(
                  color:      AppTheme.callTextPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize:   13)),
          Text(sublabel,
              style: const TextStyle(
                  color:    AppTheme.callTextSecondary,
                  fontSize: 11)),
        ],
      ),
    );
  }
}

// ── Caption box ───────────────────────────────────────────────────────────────

class _CaptionBox extends StatelessWidget {
  const _CaptionBox({
    required this.label,
    required this.text,
    required this.isMuted,
    required this.accent,
  });
  final String label;
  final String text;
  final bool isMuted;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: accent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color:        AppTheme.callTextSecondary,
              fontSize:     10,
              fontWeight:   FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: isMuted
                ? const Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.mic_off_rounded,
                            color: AppTheme.statusRinging, size: 18),
                        SizedBox(width: 6),
                        Text('Muted',
                            style: TextStyle(
                                color:    AppTheme.statusRinging,
                                fontSize: 14)),
                      ],
                    ),
                  )
                : text.isEmpty
                    ? const Center(
                        child: Text('…',
                            style: TextStyle(
                                color:    Colors.white24,
                                fontSize: 28)),
                      )
                    : Text(
                        text,
                        style: const TextStyle(
                          color:    AppTheme.callTextPrimary,
                          fontSize: 16,
                          height:   1.5,
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Control row ───────────────────────────────────────────────────────────────

class _ControlRow extends StatelessWidget {
  const _ControlRow({
    required this.isMuted,
    required this.onMute,
    required this.onEnd,
  });
  final bool isMuted;
  final VoidCallback onMute;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ControlButton(
          icon:  isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
          label: isMuted ? 'Unmute' : 'Mute',
          color: isMuted
              ? AppTheme.statusRinging
              : Colors.white.withOpacity(0.15),
          onTap: onMute,
        ),
        _ControlButton(
          icon:  Icons.call_end_rounded,
          label: 'End',
          color: AppTheme.danger,
          size:  68,
          onTap: onEnd,
          glow:  true,
        ),
        _ControlButton(
          icon:  Icons.volume_up_rounded,
          label: 'Speaker',
          color: Colors.white.withOpacity(0.15),
          onTap: () {}, // TODO: audio routing earpiece ↔ speaker
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.size = 56,
    this.glow = false,
  });
  final IconData     icon;
  final String       label;
  final Color        color;
  final VoidCallback onTap;
  final double       size;
  final bool         glow;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size, height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: glow
                  ? [BoxShadow(
                      color:        color.withOpacity(0.45),
                      blurRadius:   18,
                      spreadRadius: 2,
                    )]
                  : null,
            ),
            child: Icon(icon, color: Colors.white, size: size * 0.42),
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(
                color: AppTheme.callTextSecondary, fontSize: 12)),
      ],
    );
  }
}