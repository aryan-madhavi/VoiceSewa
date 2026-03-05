// lib/features/auth/presentation/forgot_password_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/auth_controller.dart';
import '../application/providers.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email   = TextEditingController();
  bool _sent     = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authControllerProvider.notifier)
        .sendPasswordReset(_email.text.trim());

    if (mounted && !ref.read(authControllerProvider).hasError) {
      setState(() => _sent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final error     = authState.hasError
        ? AuthController.friendlyError(authState.error!)
        : null;

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password'), elevation: 0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: _sent
              // ── Success state ──────────────────────────────────────────
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mark_email_read_outlined,
                        size: 72,
                        color: theme.colorScheme.primary),
                    const SizedBox(height: 24),
                    Text(
                      'Check your inbox',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'We sent a password reset link to ${_email.text.trim()}.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: () => context.go('/login'),
                      style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52)),
                      child: const Text('Back to Sign In'),
                    ),
                  ],
                )
              // ── Input state ────────────────────────────────────────────
              : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Forgot your password?',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Enter your email and we'll send you a reset link.",
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 32),

                      if (error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(error,
                              style: TextStyle(
                                  color:
                                      theme.colorScheme.onErrorContainer)),
                        ),
                        const SizedBox(height: 16),
                      ],

                      TextFormField(
                        controller:   _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: const InputDecoration(
                          labelText:  'Email',
                          border:     OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Enter your email';
                          }
                          if (!v.contains('@')) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      FilledButton(
                        onPressed: isLoading ? null : _submit,
                        style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52)),
                        child: isLoading
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white))
                            : const Text('Send Reset Link',
                                style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}