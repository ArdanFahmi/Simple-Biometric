import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_biometric/model/req_checklog.dart';
import 'package:simple_biometric/service/database/database_helper.dart';
import 'package:simple_biometric/utils/common.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({Key? key}) : super(key: key);
  @override
  _PinScreenState createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  void _handleSubmitPin(String pin) async {
    if (pin != "123456") {
      showSnackbar(context, "Pin Salah!", Colors.red);
    } else {
      try {
        var dbHelper = DatabaseHelper();
        await dbHelper.initDatabase();

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

        var insertCount = await dbHelper.insertPresence(request);
        if (insertCount > 0) {
          showSnackbar(context, "Data berhasil tersimpan", Colors.green);
          _navigateHome();
        } else {
          showSnackbar(context, "Data gagal tersimpan", Colors.red);
        }
      } catch (e) {
        showSnackbar(context, "Error menyimpan data: $e", Colors.red);
        rethrow;
      }
    }
  }

  void _navigateHome() {
    // TODO : Please dont use navigator.pop
    Navigator.pop(context);
    Navigator.pop(context);
    // Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
    //   builder: (context) {
    //     return const HomePage();
    //   },
    // ), (route) => false);
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
