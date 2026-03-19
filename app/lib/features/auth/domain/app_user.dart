import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_user.freezed.dart';
part 'app_user.g.dart';

@freezed
class AppUser with _$AppUser {
  const factory AppUser({
    required String uid,

    /// E.164 phone number, e.g. '+919876543210'. Set by Firebase Phone Auth.
    @Default('') String phoneNumber,

    @Default('') String displayName,

    /// BCP-47 language code stored in Firestore, e.g. 'mr-IN'
    @Default('en-IN') String lang,

    /// False until the user completes the onboarding language-selection step.
    /// The router redirects to /onboarding while this is false.
    @Default(false) bool isOnboarded,
  }) = _AppUser;

  factory AppUser.fromJson(Map<String, dynamic> json) =>
      _$AppUserFromJson(json);
}
