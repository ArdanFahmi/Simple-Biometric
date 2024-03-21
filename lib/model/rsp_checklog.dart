import 'package:json_annotation/json_annotation.dart';
part 'rsp_checklog.g.dart';

@JsonSerializable()
class RspChecklog {
  bool? result;
  String? message;
  List<RspDataChecklog>? data;

  RspChecklog({this.result, this.message, this.data});

  factory RspChecklog.fromJson(Map<String, dynamic> json) =>
      _$RspChecklogFromJson(json);
  Map<String, dynamic> toJson() => _$RspChecklogToJson(this);
}

@JsonSerializable()
class RspDataChecklog {
  String? user_record;
  String? employee_id;
  String? checklog_id;
  String? checklog_id2;
  String? notes;
  String? checklog_latitude;
  String? checklog_longitude;
  String? checklog_timestamp;
  String? checklog_event;
  String? user_modified;
  String? checklog_image_path;
  String? dt_modified;
  String? dt_record;

  RspDataChecklog(
      {this.user_record,
      this.employee_id,
      this.checklog_id,
      this.checklog_id2,
      this.notes,
      this.checklog_latitude,
      this.checklog_longitude,
      this.checklog_timestamp,
      this.checklog_event,
      this.user_modified,
      this.checklog_image_path,
      this.dt_modified,
      this.dt_record});

  factory RspDataChecklog.fromJson(Map<String, dynamic> json) =>
      _$RspDataChecklogFromJson(json);
  Map<String, dynamic> toJson() => _$RspDataChecklogToJson(this);
}
