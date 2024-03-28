// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:dio/dio.dart';
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

  void _handleSubmit() async {
    if (PhotoState.instance.pickedImage != null) {
      if (PhotoState.instance.isFormRegister) {
        _registerFaceApi();
      } else {
        _validateFaceApi();
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(builder: (context) => const PinScreen()),
        // );
      }
    } else {
      showSnackbar(context, "Foto kosong", Colors.amber);
    }
  }

  void _registerFaceApi() async {
    const url = "https://loker.interactive.co.id/register-face-api/";
    var dateNow = getDateFormattedToken();
    var plain = "$dateNow-InterActive-API";
    var token = calculateMD5(plain);

    int timestamp = DateTime.now().millisecondsSinceEpoch;
    String timeString = timestamp.toString();

    final dio = Dio();
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
      ),
    );

    try {
      var formData = FormData.fromMap({
        'token': token,
        'nama': "Fahmi",
        'noakun': timeString,
        'photo': await MultipartFile.fromFile(
            PhotoState.instance.pickedImage!.path,
            filename: "$timeString.jpg"),
      });
      final response = await dio.post(
        url,
        data: formData,
      );
      debugPrint("Response status: ${response.statusCode}");
      debugPrint("Response data: ${response.data}");
      if (response.data != null) {
        Map<String, dynamic> responseBody = response.data;
        var status = responseBody['status'];
        if (status == "success") {
          showSnackbar(context, "Data berhasil tersimpan", Colors.green);
          Navigator.pop(context);
        } else {
          showSnackbar(context, "Gagal menyimpan data", Colors.red);
        }
      }
    } catch (e) {
      showSnackbar(context, "Error menyimpan data", Colors.red);
      rethrow;
    }
  }

  void _validateFaceApi() async {
    const url = "https://loker.interactive.co.id/validate-face-api/";
    var dateNow = getDateFormattedToken();
    var plain = "$dateNow-InterActive-API";
    var token = calculateMD5(plain);

    final dio = Dio();
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
      ),
    );

    try {
      var formData = FormData.fromMap({
        'token': token,
        'noakun': "01", // TODO: get this from host
        'photo': await MultipartFile.fromFile(
            PhotoState.instance.pickedImage!.path,
            filename: "01.jpg"), // TODO: replace with noakun
      });
      final response = await dio.post(
        url,
        data: formData,
      );
      debugPrint("Response status: ${response.statusCode}");
      debugPrint("Response data: ${response.data}");
      if (response.data != null) {
        Map<String, dynamic> responseBody = response.data;
        var status = responseBody['status'];
        if (status == "success") {
          showSnackbar(context, "Berhasil validasi data", Colors.green);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PinScreen()),
          );
        } else {
          showSnackbar(context, "Data tidak valid", Colors.red);
        }
      } else {
        showSnackbar(context, "Gagal validasi data", Colors.red);
      }
    } catch (e) {
      showSnackbar(context, "Error validasi data", Colors.red);
      rethrow;
    }
  }

  @override
  void initState() {
    _takePic();
    super.initState();
  }

  @override
  void dispose() {
    PhotoState.instance.dispose();
    super.dispose();
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
              Consumer<PhotoState>(
                builder: (context, photoState, _) => ElevatedButton(
                    onPressed: _handleSubmit,
                    child: Text(
                        photoState.isFormRegister ? "Simpan" : "Selanjutnya")),
              ),
            ],
          )),
    );
  }
}
