import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:simple_biometric/photo_screen.dart';

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
    debugPrint("lat -> $lat | long -> $long");
  }

  @override
  void initState() {
    _getCurrentLocation();
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
          Text(_returnAuthorized)
        ],
      )),
    );
  }
}
