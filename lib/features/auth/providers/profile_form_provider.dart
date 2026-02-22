import 'package:flutter_riverpod/legacy.dart';

/// Tracks whether the profile form has just been completed in this session.
/// Mirrors the client app's profileCompletionProvider pattern.
class ProfileCompletionNotifier extends StateNotifier<bool> {
  ProfileCompletionNotifier() : super(false);

  void markComplete() {
    state = true;
    print('✅ Profile marked as complete');
  }

  void reset() {
    state = false;
  }
}

final profileCompletionProvider =
    StateNotifierProvider<ProfileCompletionNotifier, bool>((ref) {
      return ProfileCompletionNotifier();
    });
