// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'call_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CallSession _$CallSessionFromJson(Map<String, dynamic> json) {
  return _CallSession.fromJson(json);
}

/// @nodoc
mixin _$CallSession {
  String get sessionId =>
      throw _privateConstructorUsedError; // ── Participants ────────────────────────────────────────────────────────
  String get callerUid => throw _privateConstructorUsedError;
  String get receiverUid => throw _privateConstructorUsedError;
  String get callerName => throw _privateConstructorUsedError;
  String get receiverName =>
      throw _privateConstructorUsedError; // ── Languages (stored as sourceLang BCP-47 codes) ───────────────────────
  /// Caller's spoken language — e.g. "hi-IN"
  String get callerLang => throw _privateConstructorUsedError;

  /// Receiver's spoken language — e.g. "en-IN"
  String get receiverLang =>
      throw _privateConstructorUsedError; // ── Status ───────────────────────────────────────────────────────────────
  CallStatus get status => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime? get endedAt => throw _privateConstructorUsedError;
  int? get durationSeconds =>
      throw _privateConstructorUsedError; // ── FCM ──────────────────────────────────────────────────────────────────
  /// Receiver's FCM token — read by the Cloud Function to send the
  /// incoming call notification. Not displayed in the UI.
  String? get receiverFcmToken => throw _privateConstructorUsedError;

  /// Serializes this CallSession to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CallSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CallSessionCopyWith<CallSession> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CallSessionCopyWith<$Res> {
  factory $CallSessionCopyWith(
    CallSession value,
    $Res Function(CallSession) then,
  ) = _$CallSessionCopyWithImpl<$Res, CallSession>;
  @useResult
  $Res call({
    String sessionId,
    String callerUid,
    String receiverUid,
    String callerName,
    String receiverName,
    String callerLang,
    String receiverLang,
    CallStatus status,
    DateTime createdAt,
    DateTime? endedAt,
    int? durationSeconds,
    String? receiverFcmToken,
  });
}

/// @nodoc
class _$CallSessionCopyWithImpl<$Res, $Val extends CallSession>
    implements $CallSessionCopyWith<$Res> {
  _$CallSessionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CallSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sessionId = null,
    Object? callerUid = null,
    Object? receiverUid = null,
    Object? callerName = null,
    Object? receiverName = null,
    Object? callerLang = null,
    Object? receiverLang = null,
    Object? status = null,
    Object? createdAt = null,
    Object? endedAt = freezed,
    Object? durationSeconds = freezed,
    Object? receiverFcmToken = freezed,
  }) {
    return _then(
      _value.copyWith(
            sessionId: null == sessionId
                ? _value.sessionId
                : sessionId // ignore: cast_nullable_to_non_nullable
                      as String,
            callerUid: null == callerUid
                ? _value.callerUid
                : callerUid // ignore: cast_nullable_to_non_nullable
                      as String,
            receiverUid: null == receiverUid
                ? _value.receiverUid
                : receiverUid // ignore: cast_nullable_to_non_nullable
                      as String,
            callerName: null == callerName
                ? _value.callerName
                : callerName // ignore: cast_nullable_to_non_nullable
                      as String,
            receiverName: null == receiverName
                ? _value.receiverName
                : receiverName // ignore: cast_nullable_to_non_nullable
                      as String,
            callerLang: null == callerLang
                ? _value.callerLang
                : callerLang // ignore: cast_nullable_to_non_nullable
                      as String,
            receiverLang: null == receiverLang
                ? _value.receiverLang
                : receiverLang // ignore: cast_nullable_to_non_nullable
                      as String,
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
            receiverFcmToken: freezed == receiverFcmToken
                ? _value.receiverFcmToken
                : receiverFcmToken // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CallSessionImplCopyWith<$Res>
    implements $CallSessionCopyWith<$Res> {
  factory _$$CallSessionImplCopyWith(
    _$CallSessionImpl value,
    $Res Function(_$CallSessionImpl) then,
  ) = __$$CallSessionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String sessionId,
    String callerUid,
    String receiverUid,
    String callerName,
    String receiverName,
    String callerLang,
    String receiverLang,
    CallStatus status,
    DateTime createdAt,
    DateTime? endedAt,
    int? durationSeconds,
    String? receiverFcmToken,
  });
}

/// @nodoc
class __$$CallSessionImplCopyWithImpl<$Res>
    extends _$CallSessionCopyWithImpl<$Res, _$CallSessionImpl>
    implements _$$CallSessionImplCopyWith<$Res> {
  __$$CallSessionImplCopyWithImpl(
    _$CallSessionImpl _value,
    $Res Function(_$CallSessionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CallSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sessionId = null,
    Object? callerUid = null,
    Object? receiverUid = null,
    Object? callerName = null,
    Object? receiverName = null,
    Object? callerLang = null,
    Object? receiverLang = null,
    Object? status = null,
    Object? createdAt = null,
    Object? endedAt = freezed,
    Object? durationSeconds = freezed,
    Object? receiverFcmToken = freezed,
  }) {
    return _then(
      _$CallSessionImpl(
        sessionId: null == sessionId
            ? _value.sessionId
            : sessionId // ignore: cast_nullable_to_non_nullable
                  as String,
        callerUid: null == callerUid
            ? _value.callerUid
            : callerUid // ignore: cast_nullable_to_non_nullable
                  as String,
        receiverUid: null == receiverUid
            ? _value.receiverUid
            : receiverUid // ignore: cast_nullable_to_non_nullable
                  as String,
        callerName: null == callerName
            ? _value.callerName
            : callerName // ignore: cast_nullable_to_non_nullable
                  as String,
        receiverName: null == receiverName
            ? _value.receiverName
            : receiverName // ignore: cast_nullable_to_non_nullable
                  as String,
        callerLang: null == callerLang
            ? _value.callerLang
            : callerLang // ignore: cast_nullable_to_non_nullable
                  as String,
        receiverLang: null == receiverLang
            ? _value.receiverLang
            : receiverLang // ignore: cast_nullable_to_non_nullable
                  as String,
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
        receiverFcmToken: freezed == receiverFcmToken
            ? _value.receiverFcmToken
            : receiverFcmToken // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CallSessionImpl implements _CallSession {
  const _$CallSessionImpl({
    required this.sessionId,
    required this.callerUid,
    required this.receiverUid,
    required this.callerName,
    required this.receiverName,
    required this.callerLang,
    required this.receiverLang,
    required this.status,
    required this.createdAt,
    this.endedAt,
    this.durationSeconds,
    this.receiverFcmToken,
  });

  factory _$CallSessionImpl.fromJson(Map<String, dynamic> json) =>
      _$$CallSessionImplFromJson(json);

  @override
  final String sessionId;
  // ── Participants ────────────────────────────────────────────────────────
  @override
  final String callerUid;
  @override
  final String receiverUid;
  @override
  final String callerName;
  @override
  final String receiverName;
  // ── Languages (stored as sourceLang BCP-47 codes) ───────────────────────
  /// Caller's spoken language — e.g. "hi-IN"
  @override
  final String callerLang;

  /// Receiver's spoken language — e.g. "en-IN"
  @override
  final String receiverLang;
  // ── Status ───────────────────────────────────────────────────────────────
  @override
  final CallStatus status;
  @override
  final DateTime createdAt;
  @override
  final DateTime? endedAt;
  @override
  final int? durationSeconds;
  // ── FCM ──────────────────────────────────────────────────────────────────
  /// Receiver's FCM token — read by the Cloud Function to send the
  /// incoming call notification. Not displayed in the UI.
  @override
  final String? receiverFcmToken;

  @override
  String toString() {
    return 'CallSession(sessionId: $sessionId, callerUid: $callerUid, receiverUid: $receiverUid, callerName: $callerName, receiverName: $receiverName, callerLang: $callerLang, receiverLang: $receiverLang, status: $status, createdAt: $createdAt, endedAt: $endedAt, durationSeconds: $durationSeconds, receiverFcmToken: $receiverFcmToken)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CallSessionImpl &&
            (identical(other.sessionId, sessionId) ||
                other.sessionId == sessionId) &&
            (identical(other.callerUid, callerUid) ||
                other.callerUid == callerUid) &&
            (identical(other.receiverUid, receiverUid) ||
                other.receiverUid == receiverUid) &&
            (identical(other.callerName, callerName) ||
                other.callerName == callerName) &&
            (identical(other.receiverName, receiverName) ||
                other.receiverName == receiverName) &&
            (identical(other.callerLang, callerLang) ||
                other.callerLang == callerLang) &&
            (identical(other.receiverLang, receiverLang) ||
                other.receiverLang == receiverLang) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.endedAt, endedAt) || other.endedAt == endedAt) &&
            (identical(other.durationSeconds, durationSeconds) ||
                other.durationSeconds == durationSeconds) &&
            (identical(other.receiverFcmToken, receiverFcmToken) ||
                other.receiverFcmToken == receiverFcmToken));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    sessionId,
    callerUid,
    receiverUid,
    callerName,
    receiverName,
    callerLang,
    receiverLang,
    status,
    createdAt,
    endedAt,
    durationSeconds,
    receiverFcmToken,
  );

  /// Create a copy of CallSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CallSessionImplCopyWith<_$CallSessionImpl> get copyWith =>
      __$$CallSessionImplCopyWithImpl<_$CallSessionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CallSessionImplToJson(this);
  }
}

abstract class _CallSession implements CallSession {
  const factory _CallSession({
    required final String sessionId,
    required final String callerUid,
    required final String receiverUid,
    required final String callerName,
    required final String receiverName,
    required final String callerLang,
    required final String receiverLang,
    required final CallStatus status,
    required final DateTime createdAt,
    final DateTime? endedAt,
    final int? durationSeconds,
    final String? receiverFcmToken,
  }) = _$CallSessionImpl;

  factory _CallSession.fromJson(Map<String, dynamic> json) =
      _$CallSessionImpl.fromJson;

  @override
  String get sessionId; // ── Participants ────────────────────────────────────────────────────────
  @override
  String get callerUid;
  @override
  String get receiverUid;
  @override
  String get callerName;
  @override
  String get receiverName; // ── Languages (stored as sourceLang BCP-47 codes) ───────────────────────
  /// Caller's spoken language — e.g. "hi-IN"
  @override
  String get callerLang;

  /// Receiver's spoken language — e.g. "en-IN"
  @override
  String get receiverLang; // ── Status ───────────────────────────────────────────────────────────────
  @override
  CallStatus get status;
  @override
  DateTime get createdAt;
  @override
  DateTime? get endedAt;
  @override
  int? get durationSeconds; // ── FCM ──────────────────────────────────────────────────────────────────
  /// Receiver's FCM token — read by the Cloud Function to send the
  /// incoming call notification. Not displayed in the UI.
  @override
  String? get receiverFcmToken;

  /// Create a copy of CallSession
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CallSessionImplCopyWith<_$CallSessionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
