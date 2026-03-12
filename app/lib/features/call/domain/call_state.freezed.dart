// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'call_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$CallPhase {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(String sessionId, String receiverUid) outgoing,
    required TResult Function(
            String sessionId, String callerUid, String callerLang)
        incoming,
    required TResult Function(String sessionId) connecting,
    required TResult Function(String sessionId) active,
    required TResult Function(String? reason) ended,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(String sessionId, String receiverUid)? outgoing,
    TResult? Function(String sessionId, String callerUid, String callerLang)?
        incoming,
    TResult? Function(String sessionId)? connecting,
    TResult? Function(String sessionId)? active,
    TResult? Function(String? reason)? ended,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(String sessionId, String receiverUid)? outgoing,
    TResult Function(String sessionId, String callerUid, String callerLang)?
        incoming,
    TResult Function(String sessionId)? connecting,
    TResult Function(String sessionId)? active,
    TResult Function(String? reason)? ended,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(IdlePhase value) idle,
    required TResult Function(OutgoingPhase value) outgoing,
    required TResult Function(IncomingPhase value) incoming,
    required TResult Function(ConnectingPhase value) connecting,
    required TResult Function(ActivePhase value) active,
    required TResult Function(EndedPhase value) ended,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(IdlePhase value)? idle,
    TResult? Function(OutgoingPhase value)? outgoing,
    TResult? Function(IncomingPhase value)? incoming,
    TResult? Function(ConnectingPhase value)? connecting,
    TResult? Function(ActivePhase value)? active,
    TResult? Function(EndedPhase value)? ended,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(IdlePhase value)? idle,
    TResult Function(OutgoingPhase value)? outgoing,
    TResult Function(IncomingPhase value)? incoming,
    TResult Function(ConnectingPhase value)? connecting,
    TResult Function(ActivePhase value)? active,
    TResult Function(EndedPhase value)? ended,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CallPhaseCopyWith<$Res> {
  factory $CallPhaseCopyWith(CallPhase value, $Res Function(CallPhase) then) =
      _$CallPhaseCopyWithImpl<$Res, CallPhase>;
}

/// @nodoc
class _$CallPhaseCopyWithImpl<$Res, $Val extends CallPhase>
    implements $CallPhaseCopyWith<$Res> {
  _$CallPhaseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CallPhase
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$IdlePhaseImplCopyWith<$Res> {
  factory _$$IdlePhaseImplCopyWith(
          _$IdlePhaseImpl value, $Res Function(_$IdlePhaseImpl) then) =
      __$$IdlePhaseImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$IdlePhaseImplCopyWithImpl<$Res>
    extends _$CallPhaseCopyWithImpl<$Res, _$IdlePhaseImpl>
    implements _$$IdlePhaseImplCopyWith<$Res> {
  __$$IdlePhaseImplCopyWithImpl(
      _$IdlePhaseImpl _value, $Res Function(_$IdlePhaseImpl) _then)
      : super(_value, _then);

  /// Create a copy of CallPhase
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$IdlePhaseImpl implements IdlePhase {
  const _$IdlePhaseImpl();

  @override
  String toString() {
    return 'CallPhase.idle()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$IdlePhaseImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(String sessionId, String receiverUid) outgoing,
    required TResult Function(
            String sessionId, String callerUid, String callerLang)
        incoming,
    required TResult Function(String sessionId) connecting,
    required TResult Function(String sessionId) active,
    required TResult Function(String? reason) ended,
  }) {
    return idle();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(String sessionId, String receiverUid)? outgoing,
    TResult? Function(String sessionId, String callerUid, String callerLang)?
        incoming,
    TResult? Function(String sessionId)? connecting,
    TResult? Function(String sessionId)? active,
    TResult? Function(String? reason)? ended,
  }) {
    return idle?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(String sessionId, String receiverUid)? outgoing,
    TResult Function(String sessionId, String callerUid, String callerLang)?
        incoming,
    TResult Function(String sessionId)? connecting,
    TResult Function(String sessionId)? active,
    TResult Function(String? reason)? ended,
    required TResult orElse(),
  }) {
    if (idle != null) {
      return idle();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(IdlePhase value) idle,
    required TResult Function(OutgoingPhase value) outgoing,
    required TResult Function(IncomingPhase value) incoming,
    required TResult Function(ConnectingPhase value) connecting,
    required TResult Function(ActivePhase value) active,
    required TResult Function(EndedPhase value) ended,
  }) {
    return idle(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(IdlePhase value)? idle,
    TResult? Function(OutgoingPhase value)? outgoing,
    TResult? Function(IncomingPhase value)? incoming,
    TResult? Function(ConnectingPhase value)? connecting,
    TResult? Function(ActivePhase value)? active,
    TResult? Function(EndedPhase value)? ended,
  }) {
    return idle?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(IdlePhase value)? idle,
    TResult Function(OutgoingPhase value)? outgoing,
    TResult Function(IncomingPhase value)? incoming,
    TResult Function(ConnectingPhase value)? connecting,
    TResult Function(ActivePhase value)? active,
    TResult Function(EndedPhase value)? ended,
    required TResult orElse(),
  }) {
    if (idle != null) {
      return idle(this);
    }
    return orElse();
  }
}

abstract class IdlePhase implements CallPhase {
  const factory IdlePhase() = _$IdlePhaseImpl;
}

/// @nodoc
abstract class _$$OutgoingPhaseImplCopyWith<$Res> {
  factory _$$OutgoingPhaseImplCopyWith(
          _$OutgoingPhaseImpl value, $Res Function(_$OutgoingPhaseImpl) then) =
      __$$OutgoingPhaseImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String sessionId, String receiverUid});
}

/// @nodoc
class __$$OutgoingPhaseImplCopyWithImpl<$Res>
    extends _$CallPhaseCopyWithImpl<$Res, _$OutgoingPhaseImpl>
    implements _$$OutgoingPhaseImplCopyWith<$Res> {
  __$$OutgoingPhaseImplCopyWithImpl(
      _$OutgoingPhaseImpl _value, $Res Function(_$OutgoingPhaseImpl) _then)
      : super(_value, _then);

  /// Create a copy of CallPhase
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sessionId = null,
    Object? receiverUid = null,
  }) {
    return _then(_$OutgoingPhaseImpl(
      sessionId: null == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String,
      receiverUid: null == receiverUid
          ? _value.receiverUid
          : receiverUid // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$OutgoingPhaseImpl implements OutgoingPhase {
  const _$OutgoingPhaseImpl(
      {required this.sessionId, required this.receiverUid});

  @override
  final String sessionId;
  @override
  final String receiverUid;

  @override
  String toString() {
    return 'CallPhase.outgoing(sessionId: $sessionId, receiverUid: $receiverUid)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OutgoingPhaseImpl &&
            (identical(other.sessionId, sessionId) ||
                other.sessionId == sessionId) &&
            (identical(other.receiverUid, receiverUid) ||
                other.receiverUid == receiverUid));
  }

  @override
  int get hashCode => Object.hash(runtimeType, sessionId, receiverUid);

  /// Create a copy of CallPhase
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OutgoingPhaseImplCopyWith<_$OutgoingPhaseImpl> get copyWith =>
      __$$OutgoingPhaseImplCopyWithImpl<_$OutgoingPhaseImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(String sessionId, String receiverUid) outgoing,
    required TResult Function(
            String sessionId, String callerUid, String callerLang)
        incoming,
    required TResult Function(String sessionId) connecting,
    required TResult Function(String sessionId) active,
    required TResult Function(String? reason) ended,
  }) {
    return outgoing(sessionId, receiverUid);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(String sessionId, String receiverUid)? outgoing,
    TResult? Function(String sessionId, String callerUid, String callerLang)?
        incoming,
    TResult? Function(String sessionId)? connecting,
    TResult? Function(String sessionId)? active,
    TResult? Function(String? reason)? ended,
  }) {
    return outgoing?.call(sessionId, receiverUid);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(String sessionId, String receiverUid)? outgoing,
    TResult Function(String sessionId, String callerUid, String callerLang)?
        incoming,
    TResult Function(String sessionId)? connecting,
    TResult Function(String sessionId)? active,
    TResult Function(String? reason)? ended,
    required TResult orElse(),
  }) {
    if (outgoing != null) {
      return outgoing(sessionId, receiverUid);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(IdlePhase value) idle,
    required TResult Function(OutgoingPhase value) outgoing,
    required TResult Function(IncomingPhase value) incoming,
    required TResult Function(ConnectingPhase value) connecting,
    required TResult Function(ActivePhase value) active,
    required TResult Function(EndedPhase value) ended,
  }) {
    return outgoing(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(IdlePhase value)? idle,
    TResult? Function(OutgoingPhase value)? outgoing,
    TResult? Function(IncomingPhase value)? incoming,
    TResult? Function(ConnectingPhase value)? connecting,
    TResult? Function(ActivePhase value)? active,
    TResult? Function(EndedPhase value)? ended,
  }) {
    return outgoing?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(IdlePhase value)? idle,
    TResult Function(OutgoingPhase value)? outgoing,
    TResult Function(IncomingPhase value)? incoming,
    TResult Function(ConnectingPhase value)? connecting,
    TResult Function(ActivePhase value)? active,
    TResult Function(EndedPhase value)? ended,
    required TResult orElse(),
  }) {
    if (outgoing != null) {
      return outgoing(this);
    }
    return orElse();
  }
}

abstract class OutgoingPhase implements CallPhase {
  const factory OutgoingPhase(
      {required final String sessionId,
      required final String receiverUid}) = _$OutgoingPhaseImpl;

  String get sessionId;
  String get receiverUid;

  /// Create a copy of CallPhase
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OutgoingPhaseImplCopyWith<_$OutgoingPhaseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$IncomingPhaseImplCopyWith<$Res> {
  factory _$$IncomingPhaseImplCopyWith(
          _$IncomingPhaseImpl value, $Res Function(_$IncomingPhaseImpl) then) =
      __$$IncomingPhaseImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String sessionId, String callerUid, String callerLang});
}

/// @nodoc
class __$$IncomingPhaseImplCopyWithImpl<$Res>
    extends _$CallPhaseCopyWithImpl<$Res, _$IncomingPhaseImpl>
    implements _$$IncomingPhaseImplCopyWith<$Res> {
  __$$IncomingPhaseImplCopyWithImpl(
      _$IncomingPhaseImpl _value, $Res Function(_$IncomingPhaseImpl) _then)
      : super(_value, _then);

  /// Create a copy of CallPhase
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sessionId = null,
    Object? callerUid = null,
    Object? callerLang = null,
  }) {
    return _then(_$IncomingPhaseImpl(
      sessionId: null == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String,
      callerUid: null == callerUid
          ? _value.callerUid
          : callerUid // ignore: cast_nullable_to_non_nullable
              as String,
      callerLang: null == callerLang
          ? _value.callerLang
          : callerLang // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$IncomingPhaseImpl implements IncomingPhase {
  const _$IncomingPhaseImpl(
      {required this.sessionId,
      required this.callerUid,
      required this.callerLang});

  @override
  final String sessionId;
  @override
  final String callerUid;
  @override
  final String callerLang;

  @override
  String toString() {
    return 'CallPhase.incoming(sessionId: $sessionId, callerUid: $callerUid, callerLang: $callerLang)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$IncomingPhaseImpl &&
            (identical(other.sessionId, sessionId) ||
                other.sessionId == sessionId) &&
            (identical(other.callerUid, callerUid) ||
                other.callerUid == callerUid) &&
            (identical(other.callerLang, callerLang) ||
                other.callerLang == callerLang));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, sessionId, callerUid, callerLang);

  /// Create a copy of CallPhase
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$IncomingPhaseImplCopyWith<_$IncomingPhaseImpl> get copyWith =>
      __$$IncomingPhaseImplCopyWithImpl<_$IncomingPhaseImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(String sessionId, String receiverUid) outgoing,
    required TResult Function(
            String sessionId, String callerUid, String callerLang)
        incoming,
    required TResult Function(String sessionId) connecting,
    required TResult Function(String sessionId) active,
    required TResult Function(String? reason) ended,
  }) {
    return incoming(sessionId, callerUid, callerLang);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(String sessionId, String receiverUid)? outgoing,
    TResult? Function(String sessionId, String callerUid, String callerLang)?
        incoming,
    TResult? Function(String sessionId)? connecting,
    TResult? Function(String sessionId)? active,
    TResult? Function(String? reason)? ended,
  }) {
    return incoming?.call(sessionId, callerUid, callerLang);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(String sessionId, String receiverUid)? outgoing,
    TResult Function(String sessionId, String callerUid, String callerLang)?
        incoming,
    TResult Function(String sessionId)? connecting,
    TResult Function(String sessionId)? active,
    TResult Function(String? reason)? ended,
    required TResult orElse(),
  }) {
    if (incoming != null) {
      return incoming(sessionId, callerUid, callerLang);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(IdlePhase value) idle,
    required TResult Function(OutgoingPhase value) outgoing,
    required TResult Function(IncomingPhase value) incoming,
    required TResult Function(ConnectingPhase value) connecting,
    required TResult Function(ActivePhase value) active,
    required TResult Function(EndedPhase value) ended,
  }) {
    return incoming(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(IdlePhase value)? idle,
    TResult? Function(OutgoingPhase value)? outgoing,
    TResult? Function(IncomingPhase value)? incoming,
    TResult? Function(ConnectingPhase value)? connecting,
    TResult? Function(ActivePhase value)? active,
    TResult? Function(EndedPhase value)? ended,
  }) {
    return incoming?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(IdlePhase value)? idle,
    TResult Function(OutgoingPhase value)? outgoing,
    TResult Function(IncomingPhase value)? incoming,
    TResult Function(ConnectingPhase value)? connecting,
    TResult Function(ActivePhase value)? active,
    TResult Function(EndedPhase value)? ended,
    required TResult orElse(),
  }) {
    if (incoming != null) {
      return incoming(this);
    }
    return orElse();
  }
}

abstract class IncomingPhase implements CallPhase {
  const factory IncomingPhase(
      {required final String sessionId,
      required final String callerUid,
      required final String callerLang}) = _$IncomingPhaseImpl;

  String get sessionId;
  String get callerUid;
  String get callerLang;

  /// Create a copy of CallPhase
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$IncomingPhaseImplCopyWith<_$IncomingPhaseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ConnectingPhaseImplCopyWith<$Res> {
  factory _$$ConnectingPhaseImplCopyWith(_$ConnectingPhaseImpl value,
          $Res Function(_$ConnectingPhaseImpl) then) =
      __$$ConnectingPhaseImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String sessionId});
}

/// @nodoc
class __$$ConnectingPhaseImplCopyWithImpl<$Res>
    extends _$CallPhaseCopyWithImpl<$Res, _$ConnectingPhaseImpl>
    implements _$$ConnectingPhaseImplCopyWith<$Res> {
  __$$ConnectingPhaseImplCopyWithImpl(
      _$ConnectingPhaseImpl _value, $Res Function(_$ConnectingPhaseImpl) _then)
      : super(_value, _then);

  /// Create a copy of CallPhase
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sessionId = null,
  }) {
    return _then(_$ConnectingPhaseImpl(
      sessionId: null == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$ConnectingPhaseImpl implements ConnectingPhase {
  const _$ConnectingPhaseImpl({required this.sessionId});

  @override
  final String sessionId;

  @override
  String toString() {
    return 'CallPhase.connecting(sessionId: $sessionId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConnectingPhaseImpl &&
            (identical(other.sessionId, sessionId) ||
                other.sessionId == sessionId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, sessionId);

  /// Create a copy of CallPhase
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ConnectingPhaseImplCopyWith<_$ConnectingPhaseImpl> get copyWith =>
      __$$ConnectingPhaseImplCopyWithImpl<_$ConnectingPhaseImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(String sessionId, String receiverUid) outgoing,
    required TResult Function(
            String sessionId, String callerUid, String callerLang)
        incoming,
    required TResult Function(String sessionId) connecting,
    required TResult Function(String sessionId) active,
    required TResult Function(String? reason) ended,
  }) {
    return connecting(sessionId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(String sessionId, String receiverUid)? outgoing,
    TResult? Function(String sessionId, String callerUid, String callerLang)?
        incoming,
    TResult? Function(String sessionId)? connecting,
    TResult? Function(String sessionId)? active,
    TResult? Function(String? reason)? ended,
  }) {
    return connecting?.call(sessionId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(String sessionId, String receiverUid)? outgoing,
    TResult Function(String sessionId, String callerUid, String callerLang)?
        incoming,
    TResult Function(String sessionId)? connecting,
    TResult Function(String sessionId)? active,
    TResult Function(String? reason)? ended,
    required TResult orElse(),
  }) {
    if (connecting != null) {
      return connecting(sessionId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(IdlePhase value) idle,
    required TResult Function(OutgoingPhase value) outgoing,
    required TResult Function(IncomingPhase value) incoming,
    required TResult Function(ConnectingPhase value) connecting,
    required TResult Function(ActivePhase value) active,
    required TResult Function(EndedPhase value) ended,
  }) {
    return connecting(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(IdlePhase value)? idle,
    TResult? Function(OutgoingPhase value)? outgoing,
    TResult? Function(IncomingPhase value)? incoming,
    TResult? Function(ConnectingPhase value)? connecting,
    TResult? Function(ActivePhase value)? active,
    TResult? Function(EndedPhase value)? ended,
  }) {
    return connecting?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(IdlePhase value)? idle,
    TResult Function(OutgoingPhase value)? outgoing,
    TResult Function(IncomingPhase value)? incoming,
    TResult Function(ConnectingPhase value)? connecting,
    TResult Function(ActivePhase value)? active,
    TResult Function(EndedPhase value)? ended,
    required TResult orElse(),
  }) {
    if (connecting != null) {
      return connecting(this);
    }
    return orElse();
  }
}

abstract class ConnectingPhase implements CallPhase {
  const factory ConnectingPhase({required final String sessionId}) =
      _$ConnectingPhaseImpl;

  String get sessionId;

  /// Create a copy of CallPhase
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ConnectingPhaseImplCopyWith<_$ConnectingPhaseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ActivePhaseImplCopyWith<$Res> {
  factory _$$ActivePhaseImplCopyWith(
          _$ActivePhaseImpl value, $Res Function(_$ActivePhaseImpl) then) =
      __$$ActivePhaseImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String sessionId});
}

/// @nodoc
class __$$ActivePhaseImplCopyWithImpl<$Res>
    extends _$CallPhaseCopyWithImpl<$Res, _$ActivePhaseImpl>
    implements _$$ActivePhaseImplCopyWith<$Res> {
  __$$ActivePhaseImplCopyWithImpl(
      _$ActivePhaseImpl _value, $Res Function(_$ActivePhaseImpl) _then)
      : super(_value, _then);

  /// Create a copy of CallPhase
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sessionId = null,
  }) {
    return _then(_$ActivePhaseImpl(
      sessionId: null == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$ActivePhaseImpl implements ActivePhase {
  const _$ActivePhaseImpl({required this.sessionId});

  @override
  final String sessionId;

  @override
  String toString() {
    return 'CallPhase.active(sessionId: $sessionId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ActivePhaseImpl &&
            (identical(other.sessionId, sessionId) ||
                other.sessionId == sessionId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, sessionId);

  /// Create a copy of CallPhase
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ActivePhaseImplCopyWith<_$ActivePhaseImpl> get copyWith =>
      __$$ActivePhaseImplCopyWithImpl<_$ActivePhaseImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(String sessionId, String receiverUid) outgoing,
    required TResult Function(
            String sessionId, String callerUid, String callerLang)
        incoming,
    required TResult Function(String sessionId) connecting,
    required TResult Function(String sessionId) active,
    required TResult Function(String? reason) ended,
  }) {
    return active(sessionId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(String sessionId, String receiverUid)? outgoing,
    TResult? Function(String sessionId, String callerUid, String callerLang)?
        incoming,
    TResult? Function(String sessionId)? connecting,
    TResult? Function(String sessionId)? active,
    TResult? Function(String? reason)? ended,
  }) {
    return active?.call(sessionId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(String sessionId, String receiverUid)? outgoing,
    TResult Function(String sessionId, String callerUid, String callerLang)?
        incoming,
    TResult Function(String sessionId)? connecting,
    TResult Function(String sessionId)? active,
    TResult Function(String? reason)? ended,
    required TResult orElse(),
  }) {
    if (active != null) {
      return active(sessionId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(IdlePhase value) idle,
    required TResult Function(OutgoingPhase value) outgoing,
    required TResult Function(IncomingPhase value) incoming,
    required TResult Function(ConnectingPhase value) connecting,
    required TResult Function(ActivePhase value) active,
    required TResult Function(EndedPhase value) ended,
  }) {
    return active(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(IdlePhase value)? idle,
    TResult? Function(OutgoingPhase value)? outgoing,
    TResult? Function(IncomingPhase value)? incoming,
    TResult? Function(ConnectingPhase value)? connecting,
    TResult? Function(ActivePhase value)? active,
    TResult? Function(EndedPhase value)? ended,
  }) {
    return active?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(IdlePhase value)? idle,
    TResult Function(OutgoingPhase value)? outgoing,
    TResult Function(IncomingPhase value)? incoming,
    TResult Function(ConnectingPhase value)? connecting,
    TResult Function(ActivePhase value)? active,
    TResult Function(EndedPhase value)? ended,
    required TResult orElse(),
  }) {
    if (active != null) {
      return active(this);
    }
    return orElse();
  }
}

abstract class ActivePhase implements CallPhase {
  const factory ActivePhase({required final String sessionId}) =
      _$ActivePhaseImpl;

  String get sessionId;

  /// Create a copy of CallPhase
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ActivePhaseImplCopyWith<_$ActivePhaseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$EndedPhaseImplCopyWith<$Res> {
  factory _$$EndedPhaseImplCopyWith(
          _$EndedPhaseImpl value, $Res Function(_$EndedPhaseImpl) then) =
      __$$EndedPhaseImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String? reason});
}

/// @nodoc
class __$$EndedPhaseImplCopyWithImpl<$Res>
    extends _$CallPhaseCopyWithImpl<$Res, _$EndedPhaseImpl>
    implements _$$EndedPhaseImplCopyWith<$Res> {
  __$$EndedPhaseImplCopyWithImpl(
      _$EndedPhaseImpl _value, $Res Function(_$EndedPhaseImpl) _then)
      : super(_value, _then);

  /// Create a copy of CallPhase
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reason = freezed,
  }) {
    return _then(_$EndedPhaseImpl(
      reason: freezed == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$EndedPhaseImpl implements EndedPhase {
  const _$EndedPhaseImpl({this.reason});

  @override
  final String? reason;

  @override
  String toString() {
    return 'CallPhase.ended(reason: $reason)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EndedPhaseImpl &&
            (identical(other.reason, reason) || other.reason == reason));
  }

  @override
  int get hashCode => Object.hash(runtimeType, reason);

  /// Create a copy of CallPhase
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EndedPhaseImplCopyWith<_$EndedPhaseImpl> get copyWith =>
      __$$EndedPhaseImplCopyWithImpl<_$EndedPhaseImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(String sessionId, String receiverUid) outgoing,
    required TResult Function(
            String sessionId, String callerUid, String callerLang)
        incoming,
    required TResult Function(String sessionId) connecting,
    required TResult Function(String sessionId) active,
    required TResult Function(String? reason) ended,
  }) {
    return ended(reason);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(String sessionId, String receiverUid)? outgoing,
    TResult? Function(String sessionId, String callerUid, String callerLang)?
        incoming,
    TResult? Function(String sessionId)? connecting,
    TResult? Function(String sessionId)? active,
    TResult? Function(String? reason)? ended,
  }) {
    return ended?.call(reason);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(String sessionId, String receiverUid)? outgoing,
    TResult Function(String sessionId, String callerUid, String callerLang)?
        incoming,
    TResult Function(String sessionId)? connecting,
    TResult Function(String sessionId)? active,
    TResult Function(String? reason)? ended,
    required TResult orElse(),
  }) {
    if (ended != null) {
      return ended(reason);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(IdlePhase value) idle,
    required TResult Function(OutgoingPhase value) outgoing,
    required TResult Function(IncomingPhase value) incoming,
    required TResult Function(ConnectingPhase value) connecting,
    required TResult Function(ActivePhase value) active,
    required TResult Function(EndedPhase value) ended,
  }) {
    return ended(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(IdlePhase value)? idle,
    TResult? Function(OutgoingPhase value)? outgoing,
    TResult? Function(IncomingPhase value)? incoming,
    TResult? Function(ConnectingPhase value)? connecting,
    TResult? Function(ActivePhase value)? active,
    TResult? Function(EndedPhase value)? ended,
  }) {
    return ended?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(IdlePhase value)? idle,
    TResult Function(OutgoingPhase value)? outgoing,
    TResult Function(IncomingPhase value)? incoming,
    TResult Function(ConnectingPhase value)? connecting,
    TResult Function(ActivePhase value)? active,
    TResult Function(EndedPhase value)? ended,
    required TResult orElse(),
  }) {
    if (ended != null) {
      return ended(this);
    }
    return orElse();
  }
}

abstract class EndedPhase implements CallPhase {
  const factory EndedPhase({final String? reason}) = _$EndedPhaseImpl;

  String? get reason;

  /// Create a copy of CallPhase
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EndedPhaseImplCopyWith<_$EndedPhaseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
