import 'package:flutter_riverpod/legacy.dart';

/// Tracks whether the current session started via registration (not login).
/// This is Riverpod-only state — it resets to false on app restart,
/// which is correct: a restarting user is never "new" again.
class IsNewRegistrationNotifier extends StateNotifier<bool> {
  IsNewRegistrationNotifier() : super(false);

  void markAsNew() {
    state = true;
    print('🆕 Marked as new registration');
  }

  void reset() {
    state = false;
  }
}

final isNewRegistrationProvider =
    StateNotifierProvider<IsNewRegistrationNotifier, bool>((ref) {
      return IsNewRegistrationNotifier();
    });
