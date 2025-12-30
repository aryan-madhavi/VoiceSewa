import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/features/auth/providers/auth_provider.dart';
import 'package:voicesewa_client/features/auth/data/services/auth_service.dart';

class RegisterForm extends ConsumerStatefulWidget {
  const RegisterForm({super.key});

  @override
  ConsumerState<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends ConsumerState<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    ref.read(authLoadingProvider.notifier).state = true;

    final authService = AuthService(ref);
    final error = await authService.register(
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
      username: _usernameCtrl.text,
    );

    ref.read(authLoadingProvider.notifier).state = false;

    if (!mounted) return;

    if (error == null) {
      // Only clear on success
      _usernameCtrl.clear();
      _emailCtrl.clear();
      _passwordCtrl.clear();
      _confirmPasswordCtrl.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // Don't clear on error - keep user's input
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authLoadingProvider);
    final obscurePassword = !ref.watch(registerPasswordVisibleProvider);
    final obscureConfirmPassword = !ref.watch(confirmPasswordVisibleProvider);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Username field
          TextFormField(
            controller: _usernameCtrl,
            decoration: const InputDecoration(
              labelText: 'Username',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
            enabled: !loading,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter username';
              if (v.trim().length < 3) return 'Username too short';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Email field
          TextFormField(
            controller: _emailCtrl,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            enabled: !loading,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter email';
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                return 'Enter valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Password field
          TextFormField(
            controller: _passwordCtrl,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  ref.read(registerPasswordVisibleProvider.notifier).state =
                      !ref.read(registerPasswordVisibleProvider);
                },
              ),
            ),
            obscureText: obscurePassword,
            enabled: !loading,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter password';
              if (v.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Confirm password field
          TextFormField(
            controller: _confirmPasswordCtrl,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: const Icon(Icons.lock_outline),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  obscureConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () {
                  ref.read(confirmPasswordVisibleProvider.notifier).state =
                      !ref.read(confirmPasswordVisibleProvider);
                },
              ),
            ),
            obscureText: obscureConfirmPassword,
            enabled: !loading,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Confirm password';
              if (v != _passwordCtrl.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Submit button
          FilledButton(
            onPressed: loading ? null : _handleSubmit,
            child: loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Sign Up'),
                  ),
          ),
          const SizedBox(height: 16),

          // Toggle to login
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              TextButton(
                onPressed: loading
                    ? null
                    : () {
                        ref.read(authModeProvider.notifier).state = true;
                      },
                child: const Text('Sign In'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}