import 'package:json_annotation/json_annotation.dart';
part 'req_checklog.g.dart';

@JsonSerializable()
class ReqChecklog {
  String? checklog_id2;
  String? checklog_timestamp;
  String? checklog_event;
  String? checklog_latitude;
  String? checklog_longitude;
  String? image;
  String? employee_id;
  String? address;
  String? machine_id;
  String? company_id;

  ReqChecklog(
      {this.checklog_id2,
      this.checklog_timestamp,
      this.checklog_event,
      this.checklog_latitude,
      this.checklog_longitude,
      this.image,
      this.employee_id,
      this.address,
      this.machine_id,
      this.company_id});

  factory ReqChecklog.fromJson(Map<String, dynamic> json) =>
      _$ReqChecklogFromJson(json);
  Map<String, dynamic> toJson() => _$ReqChecklogToJson(this);
}
