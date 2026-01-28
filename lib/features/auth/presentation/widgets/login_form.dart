import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/features/auth/providers/auth_provider.dart';
import 'package:voicesewa_client/features/auth/data/services/auth_service.dart';
import 'package:voicesewa_client/features/auth/providers/profile_form_provider.dart';

class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    // CRITICAL FIX: Reset loading state when form is mounted
    // This prevents stuck loading buttons after logout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(authLoadingProvider.notifier).state = false;
      }
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    ref.read(authLoadingProvider.notifier).state = true;

    final authService = AuthService(ref);
    final error = await authService.login(
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
    );

    ref.read(authLoadingProvider.notifier).state = false;

    if (!mounted) return;

    if (error == null) {
      // Mark as login (not a new registration)
      ref.read(isNewRegistrationProvider.notifier).markAsLogin();

      // Clear form on success
      _emailCtrl.clear();
      _passwordCtrl.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login successful!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
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
    final obscurePassword = !ref.watch(loginPasswordVisibleProvider);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                  ref.read(loginPasswordVisibleProvider.notifier).state = !ref
                      .read(loginPasswordVisibleProvider);
                },
              ),
            ),
            obscureText: obscurePassword,
            enabled: !loading,
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Enter password' : null,
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
                    child: Text('Sign In'),
                  ),
          ),
          const SizedBox(height: 16),

          // Toggle to register
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Don't have an account? ",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              TextButton(
                onPressed: loading
                    ? null
                    : () {
                        ref.read(authModeProvider.notifier).state = false;
                      },
                child: const Text('Sign Up'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
