import 'package:retrofit/retrofit.dart';
import 'package:simple_biometric/model/req_checklog.dart';
import 'package:simple_biometric/model/rsp_checklog.dart';
import 'package:simple_biometric/service/retrofit/apis.dart';
import 'package:dio/dio.dart' hide Headers;

part 'api_client.g.dart';

@RestApi(baseUrl: "https://inact.interactiveholic.net/bo/api/intrax")
abstract class ApiClient {
  factory ApiClient(Dio dio, {String baseUrl}) = _ApiClient;

  @POST(Apis.submitChecklog)
  @Headers(<String, dynamic>{
    'Content-Type': 'application/json',
    'Apikey':
        'IAdev-apikey3fapikey3fed48151b389b691898cc2a046772bfa040dadb49aac02fe7b7c2f8d891dfc9ed48151b389apikey3fed48151b389b691898cc2a046772bfa040dadb49aac02fapikey3fed48151b389b691898cc2a046772bfa040dadb49aac02fe7b7c2f8d891dfc9e7b7c2f8d891dfc9b691898cc2a046772bfa040dadb49aac02fe7b7c2f8d891dfc9',
  })
  Future<RspChecklog> checklog(@Body() ReqChecklog req);
}
