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
    print('🔄 Profile completion reset');
    state = false;
  }
}

/// Provider for profile completion status
final profileCompletionProvider =
    StateNotifierProvider<ProfileCompletionNotifier, bool>((ref) {
      return ProfileCompletionNotifier();
    });

/// Notifier to track if user just registered (vs logged in)
class RegistrationStatusNotifier extends StateNotifier<bool> {
  RegistrationStatusNotifier() : super(false);

  /// Mark that user just registered (needs profile setup)
  void markAsNewRegistration() {
    print('🆕 Marking user as newly registered');
    state = true;
  }

  /// Mark that user logged in (already has profile)
  void markAsLogin() {
    print('🔐 Marking user as login (not new registration)');
    state = false;
  }

  /// Reset the registration status
  void reset() {
    print('🔄 Registration status reset');
    state = false;
  }
}

/// Provider to track if user just registered
final isNewRegistrationProvider =
    StateNotifierProvider<RegistrationStatusNotifier, bool>((ref) {
      return RegistrationStatusNotifier();
    });

// ==================== PROFILE FORM STATE ====================

/// State for profile form data
class ProfileFormState {
  final String name;
  final String phone;
  final bool isLoading;
  final String? error;

  const ProfileFormState({
    this.name = '',
    this.phone = '',
    this.isLoading = false,
    this.error,
  });

  ProfileFormState copyWith({
    String? name,
    String? phone,
    bool? isLoading,
    String? error,
  }) {
    return ProfileFormState(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for profile form state
class ProfileFormNotifier extends StateNotifier<ProfileFormState> {
  ProfileFormNotifier() : super(const ProfileFormState());

  void updateName(String name) {
    state = state.copyWith(name: name);
  }

  void updatePhone(String phone) {
    state = state.copyWith(phone: phone);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  void reset() {
    state = const ProfileFormState();
  }
}

/// Provider for profile form state
final profileFormProvider =
    StateNotifierProvider<ProfileFormNotifier, ProfileFormState>((ref) {
      return ProfileFormNotifier();
    });
