import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class InternetChecker {
  final Connectivity _connectivity = Connectivity();
  Future<void> initConnectivity() async {
    late List<ConnectivityResult> connectivityResult;

    try {
      connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.wifi)) {
        await checkInternet();
      } else if (connectivityResult.contains(ConnectivityResult.mobile)) {
        await checkInternet();
      } else if (connectivityResult.contains(ConnectivityResult.none)) {
        debugPrint("didnt connect to network ");
        //return false
      }
    } on PlatformException catch (e) {
      debugPrint("Couldn\'t check connectivity status : $e");
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> checkInternet() async {
    var result = await InternetConnectionChecker().hasConnection;
    return result;
  }
}
