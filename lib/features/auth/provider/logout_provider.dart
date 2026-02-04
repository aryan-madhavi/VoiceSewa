import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:voicesewa_worker/core/providers/session_provider.dart';

/// Logout state to track the logout process
class LogoutState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const LogoutState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  LogoutState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return LogoutState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

/// Logout Notifier to handle logout logic
class LogoutNotifier extends StateNotifier<LogoutState> {
  final Ref ref;

  LogoutNotifier(this.ref) : super(const LogoutState());

  /// Perform logout operation
  Future<void> logout() async {
    // Set loading state
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Call logout from session provider
      // This handles both Firebase and local DB logout
      await ref.read(sessionNotifierProvider.notifier).logout();

      // Set success state
      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
      );

      // Reset state after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          state = const LogoutState();
        }
      });
    } catch (e) {
      // Set error state
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );

      // Reset error after a delay
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          state = const LogoutState();
        }
      });
    }
  }

  /// Reset logout state manually if needed
  void reset() {
    state = const LogoutState();
  }
}

/// Provider for logout functionality
final logoutProvider = StateNotifierProvider<LogoutNotifier, LogoutState>((ref) {
  return LogoutNotifier(ref);
});