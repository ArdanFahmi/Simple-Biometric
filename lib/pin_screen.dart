import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_biometric/model/req_checklog.dart';
import 'package:simple_biometric/service/retrofit/api_client.dart';
import 'package:simple_biometric/utils/common.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({Key? key}) : super(key: key);
  @override
  _PinScreenState createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  void _handleSubmitPin(String pin) async {
    if (pin != "123456") {
      _showSnackbar("Pin Salah!", Colors.red);
    } else {
      final dio = Dio(); // Initialize Dio
      dio.interceptors.add(
        LogInterceptor(
          logPrint: (o) => debugPrint(o.toString()),
        ),
      );
      final client = ApiClient(Dio());
      try {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        var lat = prefs.getDouble("pref_lat");
        var long = prefs.getDouble("pref_long");

        debugPrint("lat -> $lat | long -> $long");
        var dateNow = getCurrentDateFormatted();

        var request = ReqChecklog(
            checklog_id2: "002",
            checklog_timestamp: dateNow,
            checklog_event: "CheckIn",
            checklog_latitude: lat.toString(),
            checklog_longitude: long.toString(),
            image: "",
            employee_id: "14487",
            address: "Jalan Ambengan no 85",
            machine_id: "",
            company_id: "LV0036");

        final post = await client.checklog(request);
        var result = post.result ?? false;
        if (result) {
          //success
          _showSnackbar(post.message ?? "Success Save Data", Colors.green);
        } else {
          //failed
          _showSnackbar(post.message ?? "Failed Save Data", Colors.red);
        }
      } catch (e) {
        rethrow;
      }
    }
  }

  void _showSnackbar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        action: SnackBarAction(
          textColor: Colors.white,
          label: 'Tutup',
          onPressed: () {
            // Code to execute.
          },
        ),
        backgroundColor: color,
        content: Text(msg),
        duration: const Duration(milliseconds: 1500),
        //width: 280.0, // Width of the SnackBar.
        padding: const EdgeInsets.symmetric(
          horizontal: 8.0, // Inner padding for SnackBar content.
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Input Pin"),
        ),
        body: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Center(
                child: Text(
                  "Input Pin Anda",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20.0),
                ),
              ),
              const SizedBox(
                height: 20.0,
              ),
              OtpTextField(
                numberOfFields: 6,
                borderColor: Colors.black,
                showFieldAsBox: false,
                onCodeChanged: (value) => {},
                onSubmit: (String pin) {
                  _handleSubmitPin(pin);
                },
              )
            ],
          ),
        ));
  }
}
