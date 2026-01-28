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

class RegistrationStatusNotifier extends StateNotifier<bool> {
  RegistrationStatusNotifier() : super(false);

  /// Mark that user just registered
  void markAsNewRegistration() {
    print('🆕 Marking user as newly registered');
    state = true;
  }

  /// Mark that user logged in (not a new registration)
  void markAsLogin() {
    print('🔑 Marking user as login (not new registration)');
    state = false;
  }

  /// Reset the registration status
  void reset() {
    state = false;
  }
}

/// Provider to track if user just registered
final isNewRegistrationProvider =
    StateNotifierProvider<RegistrationStatusNotifier, bool>((ref) {
      return RegistrationStatusNotifier();
    });
