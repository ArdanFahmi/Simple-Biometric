// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'req_checklog.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReqChecklog _$ReqChecklogFromJson(Map<String, dynamic> json) => ReqChecklog(
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
    );

Map<String, dynamic> _$ReqChecklogToJson(ReqChecklog instance) =>
    <String, dynamic>{
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
    };
