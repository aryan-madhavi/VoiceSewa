import 'package:freezed_annotation/freezed_annotation.dart';

part 'language_settings.freezed.dart';
part 'language_settings.g.dart';

@freezed
class LanguageSettings with _$LanguageSettings {
  const factory LanguageSettings({
    /// BCP-47 language code the user speaks, e.g. 'mr-IN'
    @Default('en-IN') String lang,
  }) = _LanguageSettings;

  factory LanguageSettings.fromJson(Map<String, dynamic> json) =>
      _$LanguageSettingsFromJson(json);
}
