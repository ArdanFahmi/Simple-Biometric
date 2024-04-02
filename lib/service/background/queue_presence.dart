import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:simple_biometric/model/presence.dart';
import 'package:simple_biometric/model/req_checklog.dart';
import 'package:simple_biometric/service/database/database_helper.dart';
import 'package:simple_biometric/service/network/internet_checker.dart';
import 'package:simple_biometric/service/retrofit/api_client.dart';

class QueuePresence {
  Future<void> getPresenceDb() async {
    bool internet = await InternetChecker().checkInternet();
    if (internet) {
      debugPrint("[Background] get presence DB");

      var dbHelper = DatabaseHelper();
      await dbHelper.initDatabase();

      var presences = await dbHelper.getPendingPresence();
      if (presences.isEmpty) {
        debugPrint("[Background] Presences is empty");
      } else {
        for (var x in presences) {
          await submitApi(x);
        }
      }
    } else {
      debugPrint("[Background] internet is offline, do nothing");
    }
  }

  Future<void> submitApi(Presence request) async {
    final dio = Dio(BaseOptions(
        sendTimeout: const Duration(minutes: 1),
        connectTimeout: const Duration(minutes: 1),
        receiveTimeout: const Duration(minutes: 1)));
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (o) => debugPrint(o.toString()),
      ),
    );
    final client = ApiClient(dio);

    try {
      var newRequest = ReqChecklog(
        checklog_id2: request.checklog_id2,
        checklog_timestamp: request.checklog_timestamp,
        checklog_event: request.checklog_event,
        checklog_latitude: request.checklog_latitude,
        checklog_longitude: request.checklog_longitude,
        image: request.image,
        employee_id: request.employee_id,
        address: request.address,
        machine_id: request.machine_id,
        company_id: request.company_id,
      );

      final post = await client.checklog(newRequest);
      var result = post.result ?? false;
      if (result) {
        await updateUploaded(request);
      } else {}
    } catch (e) {
      debugPrint("Error submit data $e");
    }
  }

  Future<void> updateUploaded(Presence data) async {
    var dbHelper = DatabaseHelper();
    await dbHelper.initDatabase();
    await dbHelper.updateUploaded(data);
  }
}
