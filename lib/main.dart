import 'dart:async';

import 'package:app_settings/app_settings.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_biometric/model/req_checklog.dart';
import 'package:simple_biometric/photo_screen.dart';
import 'package:simple_biometric/service/database/database_helper.dart';
import 'package:simple_biometric/service/network/internet_checker.dart';
import 'package:simple_biometric/service/retrofit/api_client.dart';
import 'package:simple_biometric/state/biometric_auth_state.dart';
import 'package:simple_biometric/state/internet_state.dart';
import 'package:simple_biometric/state/presence_state.dart';
import 'package:simple_biometric/utils/common.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primaryColor: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final LocalAuthentication _localAuthentication = LocalAuthentication();
  static const _platform = MethodChannel('biometric_channel');

  Future<void> _registerFingerprint() async {
    try {
      bool canCheckBiometrics = await _localAuthentication.canCheckBiometrics;
      if (canCheckBiometrics) {
        List<BiometricType> availableBiometrics =
            await _localAuthentication.getAvailableBiometrics();
        if (availableBiometrics.isEmpty) {
          // handle biometric didn't set
          _showBiometricSetupDialog();
          return;
        }
        if (availableBiometrics.contains(BiometricType.strong) ||
            availableBiometrics.contains(BiometricType.fingerprint) ||
            availableBiometrics.contains(BiometricType.face)) {
          bool didAuthenticate = await _localAuthentication.authenticate(
              localizedReason: 'Authenticate using your biometric data',
              options: const AuthenticationOptions(
                  biometricOnly: true,
                  useErrorDialogs: true,
                  stickyAuth: false));
          if (didAuthenticate) {
            _navigateNextScreen();
          } else {
            BiometricAuthState.instance.returnAuthorized = "Auth Failed";
          }
        } else {
          BiometricAuthState.instance.returnAuthorized =
              "Device not support fingerprint";
        }
      } else {
        BiometricAuthState.instance.returnAuthorized =
            "Biometric isnt avalable";
      }
    } catch (e) {
      BiometricAuthState.instance.returnAuthorized = "Error $e";
      rethrow;
    }
  }

  void _showBiometricSetupDialog() {
    showDialog(
        context: context,
        builder: (BuildContext ctx) {
          return AlertDialog(
            title: const Text("Biometric setup"),
            content: const Text(
                "There is no biometric are set in this device, please go to menu setting"),
            actions: [
              TextButton(
                  onPressed: _navigateSecuritySetting, child: const Text("OK"))
            ],
          );
        });
  }

  void _navigateSecuritySetting() async {
    AppSettings.openAppSettings(type: AppSettingsType.security);
    /*
    var url = Uri.parse(
        'package:com.android.settings/com.android.settings.SecuritySettings');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
    */
  }

  Future<void> authenticBiometric() async {
    try {
      final processedByteArray = await _platform.invokeMethod('authenticate');
      debugPrint("$processedByteArray");
      // Handle processedByteArray received from native side
    } on PlatformException catch (e) {
      // Handle platform exceptions
      debugPrint("Error authentic biometric $e");
      rethrow;
    }
  }

  void _navigateNextScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PhotoScreen()),
    );
  }

  void _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw ("GPS is unable");
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw ("Permission is Denied");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw ("Permission denied forever");
    }

    var abc = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    var lat = abc.latitude;
    var long = abc.longitude;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('pref_lat', lat);
    await prefs.setDouble('pref_long', long);

    debugPrint("lat -> $lat | long -> $long");
  }

  void _listenStatusLocation() async {
    Geolocator.getServiceStatusStream().listen((ServiceStatus status) {
      debugPrint("Status location -> $status");
    });
  }

  void _getPresenceDb() async {
    do {
      if (InternetState.instance.isConnectInternet) {
        debugPrint("get presence DB");
        await Future.delayed(const Duration(seconds: 10));

        var dbHelper = DatabaseHelper();
        await dbHelper.initDatabase();

        var presences = await dbHelper.getPresences();
        debugPrint("internet -> ${InternetState.instance.isConnectInternet}");
        if (presences.isEmpty) {
          PresenceState.instance.isPendingPresence = false;
        } else {
          PresenceState.instance.isPendingPresence = true;
          for (var x in presences) {
            if (InternetState.instance.isConnectInternet) await _submitApi(x);
          }
        }
      } else {
        debugPrint("do nothing");
        await Future.delayed(const Duration(seconds: 10));
      }
    } while (true);
  }

  Future<void> _submitApi(ReqChecklog request) async {
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
        //success
        PresenceState.instance.isFailedSubmitApi = false;
        PresenceState.instance.retrySubmitApi = 0;
        await _deletePresence(request);
      } else {
        debugPrint("Result submit api : ${post.message}");
        PresenceState.instance.isFailedSubmitApi = true;
        PresenceState.instance.retrySubmitApi += 1;
        if (PresenceState.instance.retrySubmitApi >= 3) {
          throw ("false"); //custom exception to break the loop
        } else {
          return _getPresenceDb();
        }
      }
    } catch (e) {
      debugPrint("Error submit data $e");
      if (e.toString().contains("false")) {
        //handle custom exception
        rethrow;
      } else {
        PresenceState.instance.isFailedSubmitApi = true;
        PresenceState.instance.retrySubmitApi += 1;
        if (PresenceState.instance.retrySubmitApi >= 3) {
          rethrow; //this will end the loop _getPresenceDb()
        } else {
          return _getPresenceDb();
        }
      }
    }
  }

  Future<void> _deletePresence(ReqChecklog data) async {
    var dbHelper = DatabaseHelper();
    await dbHelper.initDatabase();
    dbHelper.deletePresence(data.checklog_timestamp ??
        ""); // TODO : don't forget modif with data ID
  }

  void _listenConnectivity() async {
    Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> result) async {
      var internetChecker = InternetChecker();
      if (result.contains(ConnectivityResult.mobile) ||
          result.contains(ConnectivityResult.wifi)) {
        var result = await internetChecker.checkInternet();
        if (result) InternetState.instance.isConnectInternet = true;
      } else if (result.contains(ConnectivityResult.none)) {
        InternetState.instance.isConnectInternet = false;
        showSnackbar(context, "No internet connection", Colors.red);
      }
    });
  }

  @override
  void initState() {
    _listenStatusLocation();
    _getCurrentLocation();
    _getPresenceDb();
    _listenConnectivity();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (BuildContext context) {
          return PresenceState.instance;
        }),
        ChangeNotifierProvider(create: (BuildContext context) {
          return BiometricAuthState.instance;
        })
      ],
      child: Scaffold(
        appBar: AppBar(title: const Text("Simple Biometric")),
        body: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
                onPressed: _registerFingerprint,
                child: const Text("Authorization")),
            const SizedBox(
              height: 20,
            ),
            Consumer<BiometricAuthState>(
                builder: (context, biometricAuthState, _) =>
                    Text(biometricAuthState.returnAuthorized)),
            const SizedBox(
              height: 40.0,
            ),
            Consumer<PresenceState>(
              builder: (context, presenceState, _) => Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Visibility(
                    visible: presenceState.isPendingPresence,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Upload data ke server"),
                        const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.black)),
                        ),
                        Visibility(
                            visible: presenceState.isFailedSubmitApi,
                            child: Text(
                              "${presenceState.retrySubmitApi} / 3",
                              style: const TextStyle(color: Colors.red),
                            )),
                      ],
                    ),
                  )),
            ),
            Consumer<PresenceState>(
              builder: (context, presenceState, _) => Visibility(
                  visible: presenceState.retrySubmitApi == 3,
                  child: Column(
                    children: [
                      const SizedBox(height: 10.0),
                      ElevatedButton(
                          onPressed: () {
                            presenceState.retrySubmitApi = 0;
                            presenceState.isFailedSubmitApi = false;
                            _getPresenceDb();
                          },
                          child: const Text("Retry sync data"))
                    ],
                  )),
            )
          ],
        )),
      ),
    );
  }
}
