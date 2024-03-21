// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rsp_checklog.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RspChecklog _$RspChecklogFromJson(Map<String, dynamic> json) => RspChecklog(
      result: json['result'] as bool?,
      message: json['message'] as String?,
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => RspDataChecklog.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$RspChecklogToJson(RspChecklog instance) =>
    <String, dynamic>{
      'result': instance.result,
      'message': instance.message,
      'data': instance.data,
    };

RspDataChecklog _$RspDataChecklogFromJson(Map<String, dynamic> json) =>
    RspDataChecklog(
      user_record: json['user_record'] as String?,
      employee_id: json['employee_id'] as String?,
      checklog_id: json['checklog_id'] as String?,
      checklog_id2: json['checklog_id2'] as String?,
      notes: json['notes'] as String?,
      checklog_latitude: json['checklog_latitude'] as String?,
      checklog_longitude: json['checklog_longitude'] as String?,
      checklog_timestamp: json['checklog_timestamp'] as String?,
      checklog_event: json['checklog_event'] as String?,
      user_modified: json['user_modified'] as String?,
      checklog_image_path: json['checklog_image_path'] as String?,
      dt_modified: json['dt_modified'] as String?,
      dt_record: json['dt_record'] as String?,
    );

Map<String, dynamic> _$RspDataChecklogToJson(RspDataChecklog instance) =>
    <String, dynamic>{
      'user_record': instance.user_record,
      'employee_id': instance.employee_id,
      'checklog_id': instance.checklog_id,
      'checklog_id2': instance.checklog_id2,
      'notes': instance.notes,
      'checklog_latitude': instance.checklog_latitude,
      'checklog_longitude': instance.checklog_longitude,
      'checklog_timestamp': instance.checklog_timestamp,
      'checklog_event': instance.checklog_event,
      'user_modified': instance.user_modified,
      'checklog_image_path': instance.checklog_image_path,
      'dt_modified': instance.dt_modified,
      'dt_record': instance.dt_record,
    };
