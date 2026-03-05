// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'call_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CallSessionImpl _$$CallSessionImplFromJson(Map<String, dynamic> json) =>
    _$CallSessionImpl(
      sessionId: json['sessionId'] as String,
      callerUid: json['callerUid'] as String,
      receiverUid: json['receiverUid'] as String,
      callerName: json['callerName'] as String,
      receiverName: json['receiverName'] as String,
      callerLang: json['callerLang'] as String,
      receiverLang: json['receiverLang'] as String,
      status: $enumDecode(_$CallStatusEnumMap, json['status']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      endedAt: json['endedAt'] == null
          ? null
          : DateTime.parse(json['endedAt'] as String),
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
      receiverFcmToken: json['receiverFcmToken'] as String?,
    );

Map<String, dynamic> _$$CallSessionImplToJson(_$CallSessionImpl instance) =>
    <String, dynamic>{
      'sessionId': instance.sessionId,
      'callerUid': instance.callerUid,
      'receiverUid': instance.receiverUid,
      'callerName': instance.callerName,
      'receiverName': instance.receiverName,
      'callerLang': instance.callerLang,
      'receiverLang': instance.receiverLang,
      'status': _$CallStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'endedAt': instance.endedAt?.toIso8601String(),
      'durationSeconds': instance.durationSeconds,
      'receiverFcmToken': instance.receiverFcmToken,
    };

const _$CallStatusEnumMap = {
  CallStatus.ringing: 'ringing',
  CallStatus.active: 'active',
  CallStatus.ended: 'ended',
  CallStatus.declined: 'declined',
  CallStatus.missed: 'missed',
};
