// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'presence.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Presence _$PresenceFromJson(Map<String, dynamic> json) => Presence(
      checklog_id2: json['checklog_id2'] as String?,
      checklog_timestamp: json['checklog_timestamp'] as String?,
      checklog_event: json['checklog_event'] as String?,
      checklog_latitude: json['checklog_latitude'] as String?,
      checklog_longitude: json['checklog_longitude'] as String?,
      image: json['image'] as String?,
      employee_id: json['employee_id'] as String?,
      address: json['address'] as String?,
      machine_id: json['machine_id'] as String?,
      company_id: json['company_id'] as String?,
      is_uploaded: json['is_uploaded'] as int?,
    );

Map<String, dynamic> _$PresenceToJson(Presence instance) => <String, dynamic>{
      'checklog_id2': instance.checklog_id2,
      'checklog_timestamp': instance.checklog_timestamp,
      'checklog_event': instance.checklog_event,
      'checklog_latitude': instance.checklog_latitude,
      'checklog_longitude': instance.checklog_longitude,
      'image': instance.image,
      'employee_id': instance.employee_id,
      'address': instance.address,
      'machine_id': instance.machine_id,
      'company_id': instance.company_id,
      'is_uploaded': instance.is_uploaded,
    };
