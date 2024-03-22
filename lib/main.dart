import 'package:app_settings/app_settings.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_biometric/model/req_checklog.dart';
import 'package:simple_biometric/photo_screen.dart';
import 'package:simple_biometric/service/database/database_helper.dart';
import 'package:simple_biometric/service/retrofit/api_client.dart';

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
  String _returnAuthorized = "Not Authorized";
  static const _platform = MethodChannel('biometric_channel');
  bool _isPendingPresence = false;

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
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PhotoScreen()),
            );
          } else {
            setState(() {
              _returnAuthorized = "Auth Failed";
            });
          }
        } else {
          setState(() {
            _returnAuthorized = "Device not support fingerprint";
          });
        }
      } else {
        setState(() {
          _returnAuthorized = "Biometric isnt avalable";
        });
      }
    } catch (e) {
      setState(() {
        _returnAuthorized = "Error $e";
      });
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
      throw (e);
    }
  }

  void _getCurrentLocation() async {
    bool _serviceEnabled;
    LocationPermission _permission;

    _serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!_serviceEnabled) {
      throw ("GPS is unable");
    }

    _permission = await Geolocator.checkPermission();
    if (_permission == LocationPermission.denied) {
      _permission = await Geolocator.requestPermission();
      if (_permission == LocationPermission.denied) {
        throw ("Permission is Denied");
      }
    }

    if (_permission == LocationPermission.deniedForever) {
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

  void _getPresenceDb() async {
    var dbHelper = DatabaseHelper();
    await dbHelper.initDatabase();

    var presences = await dbHelper.getPresences();
    if (presences.isEmpty) {
      setState(() {
        _isPendingPresence = false;
      });
    } else {
      setState(() {
        _isPendingPresence = true;
      });
      for (var x in presences) {
        await _submitApi(x);
      }
      return _getPresenceDb();
    }
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

    final post = await client.checklog(request);
    var result = post.result ?? false;
    if (result) {
      //success
      await _deletePresence(request);
    }
  }

  Future<void> _deletePresence(ReqChecklog data) async {
    var dbHelper = DatabaseHelper();
    await dbHelper.initDatabase();
    dbHelper.deletePresence(data.checklog_timestamp ?? "");
  }

  @override
  void initState() {
    _getCurrentLocation();
    _getPresenceDb();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          Text(_returnAuthorized),
          const SizedBox(
            height: 40.0,
          ),
          Container(
              padding: const EdgeInsets.all(16.0),
              child: Visibility(
                visible: _isPendingPresence,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Upload data ke server"),
                    SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.black)),
                    )
                  ],
                ),
              ))
        ],
      )),
    );
  }
}
