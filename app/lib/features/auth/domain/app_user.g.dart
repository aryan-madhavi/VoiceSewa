// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AppUserImpl _$$AppUserImplFromJson(Map<String, dynamic> json) =>
    _$AppUserImpl(
      uid: json['uid'] as String,
      phoneNumber: json['phoneNumber'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      lang: json['lang'] as String? ?? 'en-IN',
      isOnboarded: json['isOnboarded'] as bool? ?? false,
    );

Map<String, dynamic> _$$AppUserImplToJson(_$AppUserImpl instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'phoneNumber': instance.phoneNumber,
      'displayName': instance.displayName,
      'lang': instance.lang,
      'isOnboarded': instance.isOnboarded,
    };
