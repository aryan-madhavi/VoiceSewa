import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/features/auth/presentation/widgets/login_form.dart';
import 'package:voicesewa_client/features/auth/presentation/widgets/register_form.dart';
import 'package:voicesewa_client/features/auth/presentation/widgets/welcome_header.dart';
import 'package:voicesewa_client/features/auth/providers/auth_provider.dart';
import 'package:voicesewa_client/features/auth/providers/session_provider.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLogin = ref.watch(authModeProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    WelcomeHeader(isLogin: isLogin),
                    const SizedBox(height: 32),
                    isLogin ? const LoginForm() : const RegisterForm(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
