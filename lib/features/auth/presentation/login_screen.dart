import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_worker/core/constants/color_constants.dart';
import 'package:voicesewa_worker/core/providers/session_provider.dart';
import 'package:voicesewa_worker/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:voicesewa_worker/features/auth/providers/auth_screen_provider.dart';
import 'package:voicesewa_worker/core/extensions/context_extensions.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    // Clear any previous error before attempting login
    ref.read(authActionsProvider.notifier).clearError();

    await ref
        .read(authActionsProvider.notifier)
        .login(_emailController.text.trim(), _passwordController.text);

    if (!mounted) return;

    // Check for error — authActionsProvider holds the error message,
    // sessionStatusProvider is untouched on failure so AppGate never
    // remounts this screen and fields are preserved.
    final authState = ref.read(authActionsProvider);
    final errorMessage = authState.value;

    if (errorMessage != null && errorMessage.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: ColorConstants.errorRed,
        ),
      );
    }
    // On success: sessionStatusProvider stream fires loggedIn →
    // AppGate switches to ProfileCheckHandler automatically.
  }

  @override
  Widget build(BuildContext context) {
    // Watch loading state from authActionsProvider only
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
                  title: context.loc.welcomeBack,
                  subtitle: context.loc.signInToContinueToVoiceSewa,
                ),

                const SizedBox(height: 48),

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
                  hint: context.loc.enterYourPassword,
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
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

                const SizedBox(height: 12),

                Align(
                  alignment: Alignment.centerRight,
                  child: AuthTextButton(
                    text: 'Forgot Password?',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(context.loc.forgotPasswordFeatureComingSoon),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                AuthButton(
                  text: 'Sign In',
                  onPressed: _handleLogin,
                  isLoading: isLoading,
                ),

                const SizedBox(height: 24),

                const AuthDivider(text: 'OR'),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(color: ColorConstants.subtitleGrey),
                    ),
                    AuthTextButton(
                      text: 'Sign Up',
                      onPressed: () {
                        ref.read(authScreenProvider.notifier).state =
                            AuthScreen.signup;
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
