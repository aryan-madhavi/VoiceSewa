// lib/features/translate_call/presentation/incoming_call_screen.dart
//
// Shown to the receiver when an incoming call arrives.
// Displayed automatically by the router when incomingCallProvider emits.
// Dark background matches the active call screen for visual continuity.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme.dart';
import '../application/providers.dart';
import '../domain/call_language.dart';
import '../domain/call_session.dart';

class IncomingCallScreen extends ConsumerStatefulWidget {
  const IncomingCallScreen({super.key, required this.session});

  final CallSession session;

  @override
  ConsumerState<IncomingCallScreen> createState() =>
      _IncomingCallScreenState();
}

class _IncomingCallScreenState extends ConsumerState<IncomingCallScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _scaleAnim = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myLanguage   = ref.watch(selectedLanguageProvider);
    final callerLang   = CallLanguage.fromSourceLang(widget.session.callerLang);
    final controller   = ref.read(callControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppTheme.callBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(),

              // ── Badge ────────────────────────────────────────────────────
              _Badge(label: 'Incoming Translated Call'),
              const SizedBox(height: 36),

              // ── Pulsing avatar ────────────────────────────────────────────
              ScaleTransition(
                scale: _scaleAnim,
                child: _Avatar(name: widget.session.callerName),
              ),
              const SizedBox(height: 22),

              // ── Caller name ───────────────────────────────────────────────
              Text(
                widget.session.callerName,
                style: Theme.of(context).textTheme.callName,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              // ── Language pair ─────────────────────────────────────────────
              _LangPair(from: callerLang, to: myLanguage),
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.translate,
                      color: AppTheme.statusActive, size: 14),
                  const SizedBox(width: 5),
                  Text(
                    'Auto-translation enabled',
                    style: TextStyle(
                        color: AppTheme.statusActive, fontSize: 13),
                  ),
                ],
              ),

              const Spacer(),

              // ── Accept / Decline ──────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CallButton(
                    icon:  Icons.call_end_rounded,
                    color: AppTheme.danger,
                    label: 'Decline',
                    onTap: () => controller.declineCall(
                        widget.session.sessionId),
                  ),
                  _CallButton(
                    icon:  Icons.call_rounded,
                    color: AppTheme.success,
                    label: 'Accept',
                    onTap: () => controller.acceptCall(
                      incomingSession: widget.session,
                      myLanguage:      myLanguage,
                    ),
                  ),
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

// ── Shared widgets ────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  const _Badge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.callTextSecondary,
          fontSize: 13,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.primary.withOpacity(0.18),
        border: Border.all(
          color: AppTheme.primary.withOpacity(0.4),
          width: 2,
        ),
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

class _LangPair extends StatelessWidget {
  const _LangPair({required this.from, required this.to});
  final CallLanguage from;
  final CallLanguage to;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LangChip(language: from),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Icon(Icons.swap_horiz_rounded,
              color: AppTheme.callTextSecondary, size: 20),
        ),
        _LangChip(language: to),
      ],
    );
  }
}

class _LangChip extends StatelessWidget {
  const _LangChip({required this.language});
  final CallLanguage language;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(language.flag, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 5),
        Text(
          language.nativeLabel,
          style: const TextStyle(
              color: AppTheme.callTextSecondary, fontSize: 14),
        ),
      ],
    );
  }
}

class _CallButton extends StatelessWidget {
  const _CallButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.45),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: const TextStyle(
                color: AppTheme.callTextSecondary, fontSize: 13)),
      ],
    );
  }
}