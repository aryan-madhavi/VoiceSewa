// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'call_history_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CallHistoryEntry _$CallHistoryEntryFromJson(Map<String, dynamic> json) {
  return _CallHistoryEntry.fromJson(json);
}

/// @nodoc
mixin _$CallHistoryEntry {
  String get sessionId =>
      throw _privateConstructorUsedError; // ── Other participant ───────────────────────────────────────────────────
  String get otherUid => throw _privateConstructorUsedError;
  String get otherName =>
      throw _privateConstructorUsedError; // ── Languages from this user's perspective ──────────────────────────────
  /// This user's spoken language — BCP-47 sourceLang e.g. "hi-IN"
  String get myLang => throw _privateConstructorUsedError;

  /// The other participant's language — BCP-47 sourceLang e.g. "en-IN"
  String get otherLang =>
      throw _privateConstructorUsedError; // ── Call metadata ───────────────────────────────────────────────────────
  CallDirection get direction => throw _privateConstructorUsedError;
  CallStatus get status => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime? get endedAt => throw _privateConstructorUsedError;
  int? get durationSeconds => throw _privateConstructorUsedError;

  /// Serializes this CallHistoryEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CallHistoryEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CallHistoryEntryCopyWith<CallHistoryEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CallHistoryEntryCopyWith<$Res> {
  factory $CallHistoryEntryCopyWith(
    CallHistoryEntry value,
    $Res Function(CallHistoryEntry) then,
  ) = _$CallHistoryEntryCopyWithImpl<$Res, CallHistoryEntry>;
  @useResult
  $Res call({
    String sessionId,
    String otherUid,
    String otherName,
    String myLang,
    String otherLang,
    CallDirection direction,
    CallStatus status,
    DateTime createdAt,
    DateTime? endedAt,
    int? durationSeconds,
  });
}

/// @nodoc
class _$CallHistoryEntryCopyWithImpl<$Res, $Val extends CallHistoryEntry>
    implements $CallHistoryEntryCopyWith<$Res> {
  _$CallHistoryEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CallHistoryEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sessionId = null,
    Object? otherUid = null,
    Object? otherName = null,
    Object? myLang = null,
    Object? otherLang = null,
    Object? direction = null,
    Object? status = null,
    Object? createdAt = null,
    Object? endedAt = freezed,
    Object? durationSeconds = freezed,
  }) {
    return _then(
      _value.copyWith(
            sessionId: null == sessionId
                ? _value.sessionId
                : sessionId // ignore: cast_nullable_to_non_nullable
                      as String,
            otherUid: null == otherUid
                ? _value.otherUid
                : otherUid // ignore: cast_nullable_to_non_nullable
                      as String,
            otherName: null == otherName
                ? _value.otherName
                : otherName // ignore: cast_nullable_to_non_nullable
                      as String,
            myLang: null == myLang
                ? _value.myLang
                : myLang // ignore: cast_nullable_to_non_nullable
                      as String,
            otherLang: null == otherLang
                ? _value.otherLang
                : otherLang // ignore: cast_nullable_to_non_nullable
                      as String,
            direction: null == direction
                ? _value.direction
                : direction // ignore: cast_nullable_to_non_nullable
                      as CallDirection,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as CallStatus,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            endedAt: freezed == endedAt
                ? _value.endedAt
                : endedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            durationSeconds: freezed == durationSeconds
                ? _value.durationSeconds
                : durationSeconds // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CallHistoryEntryImplCopyWith<$Res>
    implements $CallHistoryEntryCopyWith<$Res> {
  factory _$$CallHistoryEntryImplCopyWith(
    _$CallHistoryEntryImpl value,
    $Res Function(_$CallHistoryEntryImpl) then,
  ) = __$$CallHistoryEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String sessionId,
    String otherUid,
    String otherName,
    String myLang,
    String otherLang,
    CallDirection direction,
    CallStatus status,
    DateTime createdAt,
    DateTime? endedAt,
    int? durationSeconds,
  });
}

/// @nodoc
class __$$CallHistoryEntryImplCopyWithImpl<$Res>
    extends _$CallHistoryEntryCopyWithImpl<$Res, _$CallHistoryEntryImpl>
    implements _$$CallHistoryEntryImplCopyWith<$Res> {
  __$$CallHistoryEntryImplCopyWithImpl(
    _$CallHistoryEntryImpl _value,
    $Res Function(_$CallHistoryEntryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CallHistoryEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sessionId = null,
    Object? otherUid = null,
    Object? otherName = null,
    Object? myLang = null,
    Object? otherLang = null,
    Object? direction = null,
    Object? status = null,
    Object? createdAt = null,
    Object? endedAt = freezed,
    Object? durationSeconds = freezed,
  }) {
    return _then(
      _$CallHistoryEntryImpl(
        sessionId: null == sessionId
            ? _value.sessionId
            : sessionId // ignore: cast_nullable_to_non_nullable
                  as String,
        otherUid: null == otherUid
            ? _value.otherUid
            : otherUid // ignore: cast_nullable_to_non_nullable
                  as String,
        otherName: null == otherName
            ? _value.otherName
            : otherName // ignore: cast_nullable_to_non_nullable
                  as String,
        myLang: null == myLang
            ? _value.myLang
            : myLang // ignore: cast_nullable_to_non_nullable
                  as String,
        otherLang: null == otherLang
            ? _value.otherLang
            : otherLang // ignore: cast_nullable_to_non_nullable
                  as String,
        direction: null == direction
            ? _value.direction
            : direction // ignore: cast_nullable_to_non_nullable
                  as CallDirection,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as CallStatus,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        endedAt: freezed == endedAt
            ? _value.endedAt
            : endedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        durationSeconds: freezed == durationSeconds
            ? _value.durationSeconds
            : durationSeconds // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CallHistoryEntryImpl implements _CallHistoryEntry {
  const _$CallHistoryEntryImpl({
    required this.sessionId,
    required this.otherUid,
    required this.otherName,
    required this.myLang,
    required this.otherLang,
    required this.direction,
    required this.status,
    required this.createdAt,
    this.endedAt,
    this.durationSeconds,
  });

  factory _$CallHistoryEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$CallHistoryEntryImplFromJson(json);

  @override
  final String sessionId;
  // ── Other participant ───────────────────────────────────────────────────
  @override
  final String otherUid;
  @override
  final String otherName;
  // ── Languages from this user's perspective ──────────────────────────────
  /// This user's spoken language — BCP-47 sourceLang e.g. "hi-IN"
  @override
  final String myLang;

  /// The other participant's language — BCP-47 sourceLang e.g. "en-IN"
  @override
  final String otherLang;
  // ── Call metadata ───────────────────────────────────────────────────────
  @override
  final CallDirection direction;
  @override
  final CallStatus status;
  @override
  final DateTime createdAt;
  @override
  final DateTime? endedAt;
  @override
  final int? durationSeconds;

  @override
  String toString() {
    return 'CallHistoryEntry(sessionId: $sessionId, otherUid: $otherUid, otherName: $otherName, myLang: $myLang, otherLang: $otherLang, direction: $direction, status: $status, createdAt: $createdAt, endedAt: $endedAt, durationSeconds: $durationSeconds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CallHistoryEntryImpl &&
            (identical(other.sessionId, sessionId) ||
                other.sessionId == sessionId) &&
            (identical(other.otherUid, otherUid) ||
                other.otherUid == otherUid) &&
            (identical(other.otherName, otherName) ||
                other.otherName == otherName) &&
            (identical(other.myLang, myLang) || other.myLang == myLang) &&
            (identical(other.otherLang, otherLang) ||
                other.otherLang == otherLang) &&
            (identical(other.direction, direction) ||
                other.direction == direction) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.endedAt, endedAt) || other.endedAt == endedAt) &&
            (identical(other.durationSeconds, durationSeconds) ||
                other.durationSeconds == durationSeconds));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    sessionId,
    otherUid,
    otherName,
    myLang,
    otherLang,
    direction,
    status,
    createdAt,
    endedAt,
    durationSeconds,
  );

  /// Create a copy of CallHistoryEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CallHistoryEntryImplCopyWith<_$CallHistoryEntryImpl> get copyWith =>
      __$$CallHistoryEntryImplCopyWithImpl<_$CallHistoryEntryImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CallHistoryEntryImplToJson(this);
  }
}

abstract class _CallHistoryEntry implements CallHistoryEntry {
  const factory _CallHistoryEntry({
    required final String sessionId,
    required final String otherUid,
    required final String otherName,
    required final String myLang,
    required final String otherLang,
    required final CallDirection direction,
    required final CallStatus status,
    required final DateTime createdAt,
    final DateTime? endedAt,
    final int? durationSeconds,
  }) = _$CallHistoryEntryImpl;

  factory _CallHistoryEntry.fromJson(Map<String, dynamic> json) =
      _$CallHistoryEntryImpl.fromJson;

  @override
  String get sessionId; // ── Other participant ───────────────────────────────────────────────────
  @override
  String get otherUid;
  @override
  String get otherName; // ── Languages from this user's perspective ──────────────────────────────
  /// This user's spoken language — BCP-47 sourceLang e.g. "hi-IN"
  @override
  String get myLang;

  /// The other participant's language — BCP-47 sourceLang e.g. "en-IN"
  @override
  String get otherLang; // ── Call metadata ───────────────────────────────────────────────────────
  @override
  CallDirection get direction;
  @override
  CallStatus get status;
  @override
  DateTime get createdAt;
  @override
  DateTime? get endedAt;
  @override
  int? get durationSeconds;

  /// Create a copy of CallHistoryEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CallHistoryEntryImplCopyWith<_$CallHistoryEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
