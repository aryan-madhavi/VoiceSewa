import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_worker/core/providers/session_provider.dart';
import 'package:voicesewa_worker/features/auth/providers/auth_provider.dart';

/// Authentication service - thin wrapper around authActionsProvider.
/// Firebase Auth + Firestore only, no local database.
class AuthService {
  final WidgetRef ref;

  AuthService(this.ref);

  /// Handle user login.
  /// Returns null on success, or an error message string on failure.
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    await ref.read(authActionsProvider.notifier).login(email, password);

    final authState = ref.read(authActionsProvider);
    if (authState.value != null && authState.value!.isNotEmpty) {
      return authState.value;
    }
    return null; // success
  }

  /// Handle user registration.
  /// Returns null on success, or an error message string on failure.
  Future<String?> register({
    required String email,
    required String password,
    required String username,
  }) async {
    await ref
        .read(authActionsProvider.notifier)
        .register(email, username, password);

    final authState = ref.read(authActionsProvider);
    if (authState.value != null && authState.value!.isNotEmpty) {
      return authState.value;
    }

    // Mark as new registration so ProfileCheckHandler shows profile form
    ref.read(isNewRegistrationProvider.notifier).markAsNew();
    return null; // success
  }
}
