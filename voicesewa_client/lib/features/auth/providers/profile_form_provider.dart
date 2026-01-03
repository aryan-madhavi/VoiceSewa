import 'package:flutter_riverpod/legacy.dart';

/// Notifier to track when profile setup is completed
///
/// This allows ProfileCheckHandler to reactively navigate
/// when profile is created, without relying on manual navigation
class ProfileCompletionNotifier extends StateNotifier<bool> {
  ProfileCompletionNotifier() : super(false);

  /// Mark profile as completed
  void markComplete() {
    print('✅ Profile completion marked');
    state = true;
  }

  /// Reset completion status
  void reset() {
    state = false;
  }
}

/// Provider for profile completion status
final profileCompletionProvider =
    StateNotifierProvider<ProfileCompletionNotifier, bool>((ref) {
      return ProfileCompletionNotifier();
    });
