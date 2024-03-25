import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:simple_biometric/pin_screen.dart';
import 'package:simple_biometric/state/photo_state.dart';
import 'package:simple_biometric/utils/common.dart';

class PhotoScreen extends StatefulWidget {
  const PhotoScreen({Key? key}) : super(key: key);
  @override
  _PhotoScreenState createState() => _PhotoScreenState();
}

class _PhotoScreenState extends State<PhotoScreen> {
  final ImagePicker _picker = ImagePicker();

  void _takePic() async {
    try {
      final pickedFile = await _picker.pickImage(
          source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.front);
      if (pickedFile != null) {
        PhotoState.instance.pickedImage = pickedFile;
      } else {}
    } on PlatformException catch (e) {
      debugPrint("Error take picture $e");
      rethrow;
    }
  }

  void _navigateNextScreen() async {
    if (PhotoState.instance.pickedImage != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PinScreen()),
      );
    } else {
      showSnackbar(context, "Foto kosong", Colors.amber);
    }
  }

  @override
  void initState() {
    _takePic();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (BuildContext context) {
          return PhotoState.instance;
        })
      ],
      child: Scaffold(
          appBar: AppBar(
            title: const Text("Input Foto"),
          ),
          body: Column(
            children: [
              GestureDetector(
                onTap: () =>
                    // costom upload image
                    _takePic(),
                child: Consumer<PhotoState>(
                  builder: (context, photoState, _) => Container(
                    height: MediaQuery.of(context).size.height / 2.5,
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: photoState.pickedImage == null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.camera_alt,
                                size: 32,
                              ),
                              const SizedBox(height: 4),
                              TextButton(
                                child: const Text(
                                  'Membuka Kamera',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 16.0,
                                      color: Colors.grey),
                                ),
                                onPressed: () => _takePic(),
                              ),
                            ],
                          )
                        : AspectRatio(
                            aspectRatio: 4 / 3,
                            child: Image.file(
                              File(photoState.pickedImage!.path),
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(
                height: 20.0,
              ),
              ElevatedButton(
                  onPressed: _navigateNextScreen,
                  child: const Text("Selanjutnya")),
            ],
          )),
    );
  }
}
