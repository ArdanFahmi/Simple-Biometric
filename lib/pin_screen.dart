import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({Key? key}) : super(key: key);
  @override
  _PinScreenState createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  void _handleSubmitPin(String pin) async {
    if (pin != "123456") {
      _showSnackbar();
    } else {}
  }

  void _showSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        action: SnackBarAction(
          textColor: Colors.white,
          label: 'Tutup',
          onPressed: () {
            // Code to execute.
          },
        ),
        backgroundColor: Colors.red,
        content: const Text('Pin Salah!'),
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
