import 'package:flutter/material.dart';

class WelcomeHeader extends StatelessWidget {
  final bool isLogin;

  const WelcomeHeader({
    super.key,
    required this.isLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.voice_chat_rounded,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          isLogin ? 'Welcome Back!' : 'Create Account',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          isLogin
              ? 'Sign in to continue to VoiceSewa'
              : 'Sign up to get started with VoiceSewa',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
