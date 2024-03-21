import 'package:flutter/material.dart';

class FaceUnlockPage extends StatefulWidget {
  const FaceUnlockPage({Key? key}) : super(key: key);

  @override
  _FaceUnlockPageState createState() => _FaceUnlockPageState();
}

class _FaceUnlockPageState extends State<FaceUnlockPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Face Auth"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(onPressed: null, child: const Text("Authorization")),
            const SizedBox(
              height: 20,
            )
          ],
        ),
      ),
    );
  }
}
