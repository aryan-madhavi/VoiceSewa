import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_worker/core/constants/color_constants.dart';
import 'package:voicesewa_worker/core/providers/session_provider.dart';
import 'package:voicesewa_worker/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:voicesewa_worker/features/auth/providers/auth_provider.dart';
import 'package:voicesewa_worker/features/auth/providers/auth_screen_provider.dart';
import 'package:voicesewa_worker/core/extensions/context_extensions.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    ref.read(authActionsProvider.notifier).clearError();

    await ref
        .read(authActionsProvider.notifier)
        .register(
          _emailController.text.trim(),
          _usernameController.text.trim(),
          _passwordController.text,
        );

    if (!mounted) return;

    final authState = ref.read(authActionsProvider);

    if (authState.value == null && !authState.isLoading) {
      // Success — mark as new registration so ProfileCheckHandler shows profile form.
      // AppGate navigates automatically via sessionStatusProvider stream.
      ref.read(isNewRegistrationProvider.notifier).markAsNew();
    } else if (authState.value != null && authState.value!.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authState.value!),
          backgroundColor: ColorConstants.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authActionsProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                AuthHeader(
                  title: context.loc.createAccount,
                  subtitle: context.loc.signUpToGetStartedWithVoiceSewa,
                ),

                const SizedBox(height: 40),

                AuthTextField(
                  controller: _usernameController,
                  label: context.loc.username,
                  hint: context.loc.enterYourUsername,
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a username';
                    }
                    if (value.length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                AuthTextField(
                  controller: _emailController,
                  label: context.loc.email,
                  hint: context.loc.enterYourEmail,
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                AuthTextField(
                  controller: _passwordController,
                  label: context.loc.password,
                  hint: context.loc.createAPassword,
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: ColorConstants.unselectedGrey,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),

                const SizedBox(height: 20),

                AuthTextField(
                  controller: _confirmPasswordController,
                  label: context.loc.confirmPassword,
                  hint: context.loc.reenterYourPassword,
                  icon: Icons.lock_outline,
                  obscureText: _obscureConfirmPassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: ColorConstants.unselectedGrey,
                    ),
                    onPressed: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                AuthButton(
                  text: context.loc.createAccount,
                  onPressed: _handleSignup,
                  isLoading: isLoading,
                ),

                const SizedBox(height: 24),

                const AuthDivider(text: 'OR'),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(color: ColorConstants.subtitleGrey),
                    ),
                    AuthTextButton(
                      text: 'Sign In',
                      onPressed: () {
                        ref.read(authScreenProvider.notifier).state =
                            AuthScreen.login;
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
