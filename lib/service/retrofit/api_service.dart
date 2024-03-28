import 'dart:io';

import 'package:retrofit/retrofit.dart';
import 'package:dio/dio.dart' hide Headers;
import 'package:simple_biometric/service/retrofit/apis.dart';

part 'api_service.g.dart';

class ApiClientDev {
  final Dio dio;
  final String baseUrl;

  ApiClientDev(this.baseUrl) : dio = Dio(BaseOptions(baseUrl: baseUrl)) {
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }
}

@RestApi()
abstract class ApiService {
  factory ApiService(ApiClientDev apiClient) => _ApiService(apiClient.dio);

  @POST(Apis.registerFaceApi)
  @MultiPart()
  @Headers(<String, dynamic>{
    'Content-Type': 'multipart/form-data',
  })
  Future postRegisterFace({
    @Part(name: "token") required String token,
    @Part(name: "nama") required String nama,
    @Part(name: "noakun") required String noakun,
    @Part(name: "photo") required File photo,
  });
}
