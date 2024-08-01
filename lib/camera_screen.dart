import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:simple_biometric/face_detector_painter.dart';
import 'package:simple_biometric/utils/common.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as imglib;
import 'dart:ui' as ui;

class CameraScreen extends StatefulWidget {
  final File localImg;
  final Interpreter interpreter;
  final imglib.Image localImage;
  const CameraScreen(
      {super.key,
      required this.localImg,
      required this.interpreter,
      required this.localImage});

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
    await _startLiveFeed();
  }

  _startLiveFeed() async {
    controller = CameraController(
      _cameras[0],
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

  void _processCameraImage(CameraImage image) {
    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage != null) {
      // _processImage(inputImage);
      // _verifyFace(inputImage, widget.localImg);
      _processImageV2(inputImage, widget.localImg, widget.interpreter);
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (controller == null) return null;

    final camera = _cameras[0];
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
      InputImage inputImage, File localImage, Interpreter interpreter) async {
    if (_isBusy) return;
    _isBusy = true;
    InputImage inputLocalImage = InputImage.fromFile(localImage);

    final inputFaces = await _faceDetector.processImage(inputImage);
    final localFaces = await _faceDetector.processImage(inputLocalImage);
    if (inputFaces.isNotEmpty && localFaces.isNotEmpty) {
      imglib.Image convertedImage = decodeYUV420SP(inputImage);

      var croppedBoundary = 0;
      imglib.Image croppedImage = convertedImage;
      imglib.Image croppedLocalImage = widget.localImage;

      for (Face localFace in localFaces) {
        double x, y, w, h;
        x = (localFace.boundingBox.left - croppedBoundary);
        y = (localFace.boundingBox.top - croppedBoundary);
        w = (localFace.boundingBox.width + croppedBoundary);
        h = (localFace.boundingBox.height + croppedBoundary);

        croppedLocalImage = imglib.copyCrop(croppedLocalImage,
            x: x.round(), y: y.round(), width: w.round(), height: h.round());

        croppedLocalImage =
            imglib.copyResizeCropSquare(croppedLocalImage, size: 112);
      }
      for (Face inputFace in inputFaces) {
        double x, y, w, h;
        x = (inputFace.boundingBox.left - croppedBoundary);
        y = (inputFace.boundingBox.top - croppedBoundary);
        w = (inputFace.boundingBox.width + croppedBoundary);
        h = (inputFace.boundingBox.height + croppedBoundary);

        croppedImage = imglib.copyCrop(convertedImage,
            x: x.round(), y: y.round(), width: w.round(), height: h.round());

        croppedImage = imglib.copyResizeCropSquare(croppedImage, size: 112);
        _recognizeFace(croppedImage, croppedLocalImage);

        // List<int> pngBytes = imglib.encodePng(croppedImage);

        // // Get the temporary directory
        // final Directory tempDir = await getTemporaryDirectory();

        // // Create a unique file name
        // final String fileName =
        //     '${DateTime.now().millisecondsSinceEpoch}_coba.png';

        // // Create a file in the temporary directory
        // final File file = File('${tempDir.path}/$fileName');

        // // Write the image bytes to the file
        // await file.writeAsBytes(pngBytes);
        // throw "stopped";
      }
    }
    _isBusy = false;
  }

  void _recognizeFace(imglib.Image img, imglib.Image localImg) {
    Float32List list = imageToByteListFloat32(img, 112, 128, 128);
    Float32List list2 = imageToByteListFloat32(localImg, 112, 128, 128);

    List<dynamic> dynamicList = list.toList();
    List<dynamic> dynamicList2 = list2.toList();

    dynamicList = dynamicList.reshape([1, 112, 112, 3]);
    dynamicList2 = dynamicList2.reshape([1, 112, 112, 3]);

    List output = List.generate(1, (index) => List.filled(192, 0));
    List output2 = List.generate(1, (index) => List.filled(192, 0));

    widget.interpreter.run(dynamicList, output);
    widget.interpreter.run(dynamicList2, output2);

    output = output.reshape([192]);
    output2 = output2.reshape([192]);

    var predictedData = List.from(output);
    var predictedData2 = List.from(output2);

    compareExistSavedFaces(predictedData, predictedData2);
  }

  Future<ui.Image> convertToUiImage(imglib.Image image) async {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      Uint8List.fromList(imglib.encodePng(image)),
      image.width,
      image.height,
      ui.PixelFormat.rgba8888,
      (img) => completer.complete(img),
    );
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    if (!controller!.value.isInitialized) {
      return Container();
    }
    return MaterialApp(
      home: CameraPreview(
        controller!,
        child: _customPaint,
      ),
    );
  }
}
