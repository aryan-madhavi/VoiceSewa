// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'language_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

LanguageSettings _$LanguageSettingsFromJson(Map<String, dynamic> json) {
  return _LanguageSettings.fromJson(json);
}

/// @nodoc
mixin _$LanguageSettings {
  /// BCP-47 language code the user speaks, e.g. 'mr-IN'
  String get lang => throw _privateConstructorUsedError;

  /// Serializes this LanguageSettings to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LanguageSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LanguageSettingsCopyWith<LanguageSettings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LanguageSettingsCopyWith<$Res> {
  factory $LanguageSettingsCopyWith(
          LanguageSettings value, $Res Function(LanguageSettings) then) =
      _$LanguageSettingsCopyWithImpl<$Res, LanguageSettings>;
  @useResult
  $Res call({String lang});
}

/// @nodoc
class _$LanguageSettingsCopyWithImpl<$Res, $Val extends LanguageSettings>
    implements $LanguageSettingsCopyWith<$Res> {
  _$LanguageSettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LanguageSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? lang = null,
  }) {
    return _then(_value.copyWith(
      lang: null == lang
          ? _value.lang
          : lang // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LanguageSettingsImplCopyWith<$Res>
    implements $LanguageSettingsCopyWith<$Res> {
  factory _$$LanguageSettingsImplCopyWith(_$LanguageSettingsImpl value,
          $Res Function(_$LanguageSettingsImpl) then) =
      __$$LanguageSettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String lang});
}

/// @nodoc
class __$$LanguageSettingsImplCopyWithImpl<$Res>
    extends _$LanguageSettingsCopyWithImpl<$Res, _$LanguageSettingsImpl>
    implements _$$LanguageSettingsImplCopyWith<$Res> {
  __$$LanguageSettingsImplCopyWithImpl(_$LanguageSettingsImpl _value,
      $Res Function(_$LanguageSettingsImpl) _then)
      : super(_value, _then);

  /// Create a copy of LanguageSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? lang = null,
  }) {
    return _then(_$LanguageSettingsImpl(
      lang: null == lang
          ? _value.lang
          : lang // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LanguageSettingsImpl implements _LanguageSettings {
  const _$LanguageSettingsImpl({this.lang = 'en-IN'});

  factory _$LanguageSettingsImpl.fromJson(Map<String, dynamic> json) =>
      _$$LanguageSettingsImplFromJson(json);

  /// BCP-47 language code the user speaks, e.g. 'mr-IN'
  @override
  @JsonKey()
  final String lang;

  @override
  String toString() {
    return 'LanguageSettings(lang: $lang)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LanguageSettingsImpl &&
            (identical(other.lang, lang) || other.lang == lang));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, lang);

  /// Create a copy of LanguageSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LanguageSettingsImplCopyWith<_$LanguageSettingsImpl> get copyWith =>
      __$$LanguageSettingsImplCopyWithImpl<_$LanguageSettingsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LanguageSettingsImplToJson(
      this,
    );
  }
}

abstract class _LanguageSettings implements LanguageSettings {
  const factory _LanguageSettings({final String lang}) = _$LanguageSettingsImpl;

  factory _LanguageSettings.fromJson(Map<String, dynamic> json) =
      _$LanguageSettingsImpl.fromJson;

  /// BCP-47 language code the user speaks, e.g. 'mr-IN'
  @override
  String get lang;

  /// Create a copy of LanguageSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LanguageSettingsImplCopyWith<_$LanguageSettingsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
