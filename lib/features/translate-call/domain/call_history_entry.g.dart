// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'call_history_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CallHistoryEntryImpl _$$CallHistoryEntryImplFromJson(
  Map<String, dynamic> json,
) => _$CallHistoryEntryImpl(
  sessionId: json['sessionId'] as String,
  otherUid: json['otherUid'] as String,
  otherName: json['otherName'] as String,
  myLang: json['myLang'] as String,
  otherLang: json['otherLang'] as String,
  direction: $enumDecode(_$CallDirectionEnumMap, json['direction']),
  status: $enumDecode(_$CallStatusEnumMap, json['status']),
  createdAt: DateTime.parse(json['createdAt'] as String),
  endedAt: json['endedAt'] == null
      ? null
      : DateTime.parse(json['endedAt'] as String),
  durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
);

Map<String, dynamic> _$$CallHistoryEntryImplToJson(
  _$CallHistoryEntryImpl instance,
) => <String, dynamic>{
  'sessionId': instance.sessionId,
  'otherUid': instance.otherUid,
  'otherName': instance.otherName,
  'myLang': instance.myLang,
  'otherLang': instance.otherLang,
  'direction': _$CallDirectionEnumMap[instance.direction]!,
  'status': _$CallStatusEnumMap[instance.status]!,
  'createdAt': instance.createdAt.toIso8601String(),
  'endedAt': instance.endedAt?.toIso8601String(),
  'durationSeconds': instance.durationSeconds,
};

const _$CallDirectionEnumMap = {
  CallDirection.outgoing: 'outgoing',
  CallDirection.incoming: 'incoming',
};

const _$CallStatusEnumMap = {
  CallStatus.ringing: 'ringing',
  CallStatus.active: 'active',
  CallStatus.ended: 'ended',
  CallStatus.declined: 'declined',
  CallStatus.missed: 'missed',
};
