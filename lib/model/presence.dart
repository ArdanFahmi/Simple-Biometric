import 'package:json_annotation/json_annotation.dart';
part 'presence.g.dart';

@JsonSerializable()
class Presence {
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
  int? is_uploaded;

  Presence(
      {this.checklog_id2,
      this.checklog_timestamp,
      this.checklog_event,
      this.checklog_latitude,
      this.checklog_longitude,
      this.image,
      this.employee_id,
      this.address,
      this.machine_id,
      this.company_id,
      this.is_uploaded});

  factory Presence.fromJson(Map<String, dynamic> json) =>
      _$PresenceFromJson(json);
  Map<String, dynamic> toJson() => _$PresenceToJson(this);
}
