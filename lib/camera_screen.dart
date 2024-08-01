// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:simple_biometric/face_detector_painter.dart';
import 'package:simple_biometric/utils/common.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as imglib;

class CameraScreen extends StatefulWidget {
  final Interpreter interpreter;
  final imglib.Image localImage;
  final List<dynamic> listRecognizeLocalImg;
  const CameraScreen(
      {super.key,
      required this.interpreter,
      required this.localImage,
      required this.listRecognizeLocalImg});

  @override
  // ignore: library_private_types_in_public_api
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool _isBusy = false;
  late CameraController? controller;
  late List<CameraDescription> _cameras;
  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
    ),
  );
  CustomPaint? _customPaint;
  bool _changingCameraLens = false;
  int _cameraIndex = -1;
  final _cameraLensDirection = CameraLensDirection.front;

  @override
  void initState() {
    super.initState();
    _intialize();
  }

  @override
  void dispose() {
    // controller.dispose();
    _stopLiveFeed();
    super.dispose();
  }

  _intialize() async {
    _cameras = await availableCameras();
    for (var i = 0; i < _cameras.length; i++) {
      if (_cameras[i].lensDirection == _cameraLensDirection) {
        _cameraIndex = i;
        break;
      }
    }
    if (_cameraIndex != -1) {
      _startLiveFeed();
    }
  }

  _startLiveFeed() async {
    final camera = _cameras[_cameraIndex];
    controller = CameraController(
      camera,
      // Set to ResolutionPreset.high. Do NOT set it to ResolutionPreset.max because for some phones does NOT work.
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );
    controller?.initialize().then((_) {
      controller?.startImageStream(_processCameraImage).then((value) {});
      setState(() {}); //refresh state
    });
  }

  _stopLiveFeed() async {
    await controller?.stopImageStream();
    await controller?.dispose();
    controller = null;
  }

  Future _switchLiveCamera() async {
    setState(() => _changingCameraLens = true);
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;

    await _stopLiveFeed();
    await _startLiveFeed();
    setState(() => _changingCameraLens = false);
  }

  void _processCameraImage(CameraImage image) {
    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage != null) {
      // _processImage(inputImage);
      // _verifyFace(inputImage, widget.localImg);
      _processImageV2(inputImage, widget.interpreter);
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (controller == null) return null;

    final camera = _cameras[_cameraIndex];
    final sensorOrientation = camera.sensorOrientation;
    // print(
    //     'lensDirection: ${camera.lensDirection}, sensorOrientation: $sensorOrientation, ${controller.value.deviceOrientation} ${controller.value.lockedCaptureOrientation} ${controller.value.isCaptureOrientationLocked}');
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[controller?.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        // front-facing
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        // back-facing
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
      // print('rotationCompensation: $rotationCompensation');
    }
    if (rotation == null) return null;
    // print('final rotation: $rotation');
    // get image format
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    // validate format depending on platform
    // only supported formats:
    // * nv21 for Android
    // * bgra8888 for iOS
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) return null;

    // since format is constraint to nv21 or bgra8888, both only have one plane
    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    // compose InputImage using bytes
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation, // used only in Android
        format: format, // used only in iOS
        bytesPerRow: plane.bytesPerRow, // used only in iOS
      ),
    );
  }

  Future<void> _processImage(InputImage inputImage) async {
    if (_isBusy) return;
    _isBusy = true;
    final faces = await _faceDetector.processImage(inputImage);
    if (faces.isNotEmpty) {
      final painter = FaceDetectorPainter(
        faces,
        inputImage.metadata!.size,
        inputImage.metadata!.rotation,
        CameraLensDirection.front,
      );
      _customPaint = CustomPaint(painter: painter);
    }
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _verifyFace(InputImage inputImage, File localImage) async {
    if (_isBusy) return;
    _isBusy = true;

    InputImage inputLocalImage = InputImage.fromFile(localImage);

    final inputFaces = await _faceDetector.processImage(inputImage);
    final localFaces = await _faceDetector.processImage(inputLocalImage);

    if (inputFaces.isNotEmpty && localFaces.isNotEmpty) {
      final Face runtimeFace = inputFaces[0];
      final Face localFace = localFaces[0];

      // print("coba $inputFaces");

      // Compare the faces (You can use facial landmarks for a more detailed comparison)
      // bool isVerified = runtimeFace.boundingBox == localFace.boundingBox;
      // print("is verified -> $isVerified");
      // // Clean up resources
      // _faceDetector.close();

      // Check for landmarks, e.g., left and right eye positions
      final FaceLandmark? runtimeLeftEye =
          runtimeFace.landmarks[FaceLandmarkType.leftEye];
      final FaceLandmark? runtimeRightEye =
          runtimeFace.landmarks[FaceLandmarkType.rightEye];
      final FaceLandmark? localLeftEye =
          localFace.landmarks[FaceLandmarkType.leftEye];
      final FaceLandmark? localRightEye =
          localFace.landmarks[FaceLandmarkType.rightEye];

      if (runtimeLeftEye != null &&
          runtimeRightEye != null &&
          localLeftEye != null &&
          localRightEye != null) {
        // Compare the positions of the left and right eyes
        // print(
        //     'Runtime Left Eye Position: (${runtimeLeftEye.position.x}, ${runtimeLeftEye.position.y})');
        // print(
        //     'Runtime Right Eye Position: (${runtimeRightEye.position.x}, ${runtimeRightEye.position.y})');
        // print(
        //     'Local Left Eye Position: (${localLeftEye.position.x}, ${localLeftEye.position.y})');
        // print(
        //     'Local Right Eye Position: (${localRightEye.position.x}, ${localRightEye.position.y})');

        double runtimeDistance = calculateDistance(
          runtimeLeftEye.position.x,
          runtimeLeftEye.position.y,
          runtimeRightEye.position.x,
          runtimeRightEye.position.y,
        );
        double localDistance = calculateDistance(
          localLeftEye.position.x,
          localLeftEye.position.y,
          localRightEye.position.x,
          localRightEye.position.y,
        );

        // Define a threshold for similarity
        double similarityThreshold = 20.0;

        var abc = (runtimeDistance - localDistance).abs() < similarityThreshold;
        print("is verified bos -> $abc");
      }
    }
    _isBusy = false;
  }

  double calculateDistance(int x1, int y1, int x2, int y2) {
    return sqrt(pow(x2 - x1, 2) + pow(y2 - y1, 2));
  }

  Future<void> _processImageV2(
      InputImage inputImage, Interpreter interpreter) async {
    if (_isBusy) return;
    _isBusy = true;

    final inputFaces = await _faceDetector.processImage(inputImage);
    if (inputFaces.isNotEmpty) {
      imglib.Image convertedImage =
          decodeYUV420SP(inputImage, _cameraLensDirection);

      var croppedBoundary = 0;
      imglib.Image croppedImage = convertedImage;
      for (Face inputFace in inputFaces) {
        double x, y, w, h;
        x = (inputFace.boundingBox.left - croppedBoundary);
        y = (inputFace.boundingBox.top - croppedBoundary);
        w = (inputFace.boundingBox.width + croppedBoundary);
        h = (inputFace.boundingBox.height + croppedBoundary);

        croppedImage = imglib.copyCrop(convertedImage,
            x: x.round(), y: y.round(), width: w.round(), height: h.round());

        croppedImage = imglib.copyResizeCropSquare(croppedImage, size: 112);
      }
      final painter = FaceDetectorPainter(inputFaces, inputImage.metadata!.size,
          inputImage.metadata!.rotation, _cameraLensDirection);
      _customPaint = CustomPaint(painter: painter);

      var listRecognizeStreamImg = recognizeFace(croppedImage, interpreter);
      String resultCompare = compareExistSavedFaces(
          listRecognizeStreamImg, widget.listRecognizeLocalImg);

      if (resultCompare == "VERIFIED") {
        await _stopLiveFeed();
        showDialogLoading(context);

        setState(() {}); //refresh state
        await Future.delayed(const Duration(seconds: 1));

        String resultPredicted = await _predictImage(croppedImage);

        Navigator.pop(context); //close dialog
        showSnackbar(context, resultPredicted,
            resultPredicted == "REAL" ? Colors.green : Colors.red);
      }
    } else {
      _customPaint = null;
    }
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }

  // result : printed or real
  Future<String> _predictImage(imglib.Image imgStream) async {
    imglib.Image resizedImage =
        imglib.copyResize(imgStream, width: 64, height: 64);

    // Normalize the image data
    List<List<List<double>>> input = List.generate(
        64,
        (y) => List.generate(64, (x) {
              imglib.Pixel pixel = resizedImage.getPixel(x, y);

              var r = pixel[0] / 255.0;
              var g = pixel[1] / 255.0;
              var b = pixel[2] / 255.0;

              return [r, g, b];
            }));

    List<List<List<List<double>>>> inputTensor = [input];
    // Load the model and predict
    var output = List.filled(1 * 1, 0.0).reshape([1, 1]);

    final interpreter = await Interpreter.fromAsset(
        'assets/real_printed_face_model_CNN.tflite');
    interpreter.run(inputTensor, output);

    double prediction = output[0][0];
    return prediction > 0.5 ? "REAL" : "PRINTED";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _liveFeedBody(context));
  }

  Widget _liveFeedBody(BuildContext ctx) {
    if (_cameras.isEmpty) return Container();
    if (controller == null) return Container();
    if (controller?.value.isInitialized == false) return Container();
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Center(
            child: _changingCameraLens
                ? const Center(
                    child: Text('Changing camera lens'),
                  )
                : CameraPreview(
                    controller!,
                    child: _customPaint,
                  ),
          ),
          _backButton(ctx),
          _switchLiveCameraToggle(),
        ],
      ),
    );
  }

  Widget _backButton(BuildContext ctx) => Positioned(
        top: 40,
        left: 8,
        child: SizedBox(
          height: 50.0,
          width: 50.0,
          child: FloatingActionButton(
            heroTag: Object(),
            onPressed: () => Navigator.of(ctx).pop(),
            backgroundColor: Colors.black54,
            child: const Icon(
              Icons.arrow_back_ios_outlined,
              size: 20,
              color: Colors.white,
            ),
          ),
        ),
      );

  Widget _switchLiveCameraToggle() => Positioned(
        bottom: 8,
        right: 8,
        child: SizedBox(
          height: 50.0,
          width: 50.0,
          child: FloatingActionButton(
            heroTag: Object(),
            onPressed: _switchLiveCamera,
            backgroundColor: Colors.black54,
            child: Icon(
              Platform.isIOS
                  ? Icons.flip_camera_ios_outlined
                  : Icons.flip_camera_android_outlined,
              size: 25,
              color: Colors.white,
            ),
          ),
        ),
      );
}
