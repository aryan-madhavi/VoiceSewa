import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../data/auth_repository.dart';

/// Two-step phone auth screen.
///
/// Step 1 — phone number entry → tapping "Send OTP" calls Firebase
///           verifyPhoneNumber and advances to step 2.
/// Step 2 — 6-digit OTP entry → tapping "Verify" calls signInWithCredential.
///           On Android the SMS Retriever API may auto-fill and skip step 2.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // ── State ──────────────────────────────────────────────────────────────────
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  // Moves to OTP step once the SMS has been sent.
  bool _otpSent = false;
  String? _verificationId;
  int? _resendToken;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  // toE164() is the shared normaliser from core/constants.dart.

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _sendOtp() async {
    final phone = toE164(_phoneCtrl.text.trim());
    if (phone.length < 10) {
      setState(() => _error = 'Enter a valid phone number');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    await ref.read(authRepositoryProvider).sendOtp(
      phone,
      onCodeSent: (verificationId, resendToken) {
        if (!mounted) return;
        setState(() {
          _verificationId = verificationId;
          _resendToken = resendToken;
          _otpSent = true;
          _loading = false;
        });
      },
      onFailed: (e) {
        if (!mounted) return;
        setState(() {
          _error = e.message ?? 'Failed to send OTP';
          _loading = false;
        });
      },
      // Android SMS Retriever: auto-verify without user typing the code.
      onAutoVerified: (credential) async {
        if (!mounted) return;
        setState(() => _loading = true);
        try {
          await FirebaseAuth.instance.signInWithCredential(credential);
          // Router redirect handles navigation.
        } catch (e) {
          if (mounted) setState(() => _error = e.toString());
        } finally {
          if (mounted) setState(() => _loading = false);
        }
      },
    );
  }

  Future<void> _verifyOtp() async {
    final code = _otpCtrl.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Enter the 6-digit code');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .confirmOtp(_verificationId!, code);
      // Router redirect handles navigation.
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Invalid code');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo / title
                  Icon(Icons.translate_rounded,
                      size: 64, color: cs.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Vaani',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Call anyone. Speak your language.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface.withValues(alpha: .6),
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  if (!_otpSent) ...[
                    // ── Step 1: phone number ───────────────────────────────
                    Text('Enter your phone number',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s\-()]')),
                      ],
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.phone),
                        hintText: '+91 98765 43210',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _loading ? null : _sendOtp(),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _loading ? null : _sendOtp,
                      child: _loading
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Send OTP'),
                    ),
                  ] else ...[
                    // ── Step 2: OTP ────────────────────────────────────────
                    Text(
                      'We sent a code to\n${toE164(_phoneCtrl.text.trim())}',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _otpCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.lock_outline),
                        hintText: '6-digit code',
                        border: OutlineInputBorder(),
                        counterText: '',
                      ),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                      onSubmitted: (_) => _loading ? null : _verifyOtp(),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _loading ? null : _verifyOtp,
                      child: _loading
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Verify'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: _loading
                              ? null
                              : () => setState(() {
                                    _otpSent = false;
                                    _otpCtrl.clear();
                                    _error = null;
                                  }),
                          child: const Text('Change number'),
                        ),
                        // Re-uses the resendToken from the previous sendOtp call
                        // so Firebase doesn't count this as a fresh SMS quota hit.
                        TextButton(
                          onPressed: _loading
                              ? null
                              : () async {
                                  final phone =
                                      toE164(_phoneCtrl.text.trim());
                                  setState(() {
                                    _loading = true;
                                    _error = null;
                                  });
                                  await ref
                                      .read(authRepositoryProvider)
                                      .sendOtp(
                                        phone,
                                        resendToken: _resendToken,
                                        onCodeSent:
                                            (verificationId, resendToken) {
                                          if (!mounted) return;
                                          setState(() {
                                            _verificationId = verificationId;
                                            _resendToken = resendToken;
                                            _loading = false;
                                          });
                                        },
                                        onFailed: (e) {
                                          if (!mounted) return;
                                          setState(() {
                                            _error = e.message ??
                                                'Failed to resend OTP';
                                            _loading = false;
                                          });
                                        },
                                      );
                                },
                          child: const Text('Resend OTP'),
                        ),
                      ],
                    ),
                  ],

                  // Error message
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(color: cs.error),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
