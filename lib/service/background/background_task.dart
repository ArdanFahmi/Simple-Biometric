import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/material.dart';

/*
  0 : STATUS_RESTRICTED
  1 : STATUS_DENIED
  2 : STATUS_AVAILABLE
*/
class BackgroundTask {
  Future<int> startBackgroundTaskGetPresenceDb() async {
    int status = await BackgroundFetch.configure(
        BackgroundFetchConfig(
            minimumFetchInterval: 15,
            stopOnTerminate: false,
            enableHeadless: true,
            requiresBatteryNotLow: false,
            requiresCharging: false,
            requiresStorageNotLow: false,
            requiresDeviceIdle: false,
            requiredNetworkType: NetworkType.NONE), (String taskId) async {
      debugPrint("[BackgroundFetch] Event received $taskId");

      BackgroundFetch.finish(taskId);
    }, (String taskId) async {
      debugPrint("[BackgroundFetch] TASK TIMEOUT taskId: $taskId");
      BackgroundFetch.finish(taskId);
    });
    debugPrint('[BackgroundFetch] configure success: $status');
    return status;
  }

  Future<int> startTask() async {
    int status = await BackgroundFetch.start();
    debugPrint("[BackgroundFetch] Start task $status");
    return status;
  }

  Future<int> stopTask() async {
    int status = await BackgroundFetch.stop();
    debugPrint("[BackgroundFetch] Stop task $status");
    return status;
  }

  Future<int> statusTask() async {
    int status = await BackgroundFetch.status;
    debugPrint("[BackgroundFetch] Status Task $status");
    return status;
  }
}
