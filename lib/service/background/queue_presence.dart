import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
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

      var presences = await dbHelper.getPresences();
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

  Future<void> submitApi(ReqChecklog request) async {
    final dio = Dio();
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (o) => debugPrint(o.toString()),
      ),
    );
    final client = ApiClient(dio);

    try {
      final post = await client.checklog(request);
      var result = post.result ?? false;
      if (result) {
        await deletePresence(request);
      } else {}
    } catch (e) {
      debugPrint("Error submit data $e");
    }
  }

  Future<void> deletePresence(ReqChecklog data) async {
    var dbHelper = DatabaseHelper();
    await dbHelper.initDatabase();
    await dbHelper.deletePresence(data.checklog_timestamp ??
        ""); // TODO : don't forget modif with data ID
  }
}
