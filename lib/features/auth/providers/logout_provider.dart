import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:voicesewa_worker/core/providers/session_provider.dart';

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

class LogoutNotifier extends StateNotifier<LogoutState> {
  final Ref ref;

  LogoutNotifier(this.ref) : super(const LogoutState());

  Future<void> logout() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Now delegates to authActionsProvider instead of sessionNotifierProvider
      await ref.read(authActionsProvider.notifier).logout();

      state = state.copyWith(isLoading: false, isSuccess: true);

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) state = const LogoutState();
      });
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) state = const LogoutState();
      });
    }
  }

  void reset() => state = const LogoutState();
}

final logoutProvider = StateNotifierProvider<LogoutNotifier, LogoutState>((
  ref,
) {
  return LogoutNotifier(ref);
});
