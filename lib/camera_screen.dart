import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
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

  static imglib.Image? _convertCameraImage(
      CameraImage image, CameraLensDirection direction) {
    try {
      imglib.Image img;
      if (image.format.group == ImageFormatGroup.yuv420) {
        img = _convertYUV420(image, direction);
      } else if (image.format.group == ImageFormatGroup.bgra8888) {
        img = _convertBGRA8888(image, direction);
      } else if (image.format.group == ImageFormatGroup.nv21) {
        // Uint8List.fromList(elements)
        // final Uint8List newImg =
        //     Uint8List.fromList(imglib.encodeJpg(image as imglib.Image));
        // var abc = _nv21ToImage(nv21, width, height);
        // imglib.Image image2 = imglib.decodeImage(newImg)!;
        // img = image2;
        img = nv21ToImage(image);
      } else {
        throw UnsupportedError(
            'Unsupported image format: ${image.format.group}');
      }
      return img;
    } catch (e) {
      print("Error converting image: $e");
      return null;
    }
  }

  static Future<Uint8List> _nv21ToImage(
      Uint8List nv21, int width, int height) async {
    final imglib.Image image = _convertNV21ToRGBImage(nv21, width, height);
    final Uint8List newImg = Uint8List.fromList(imglib.encodeJpg(image));
    return newImg;
  }

  static imglib.Image _convertNV21ToRGBImage(
      Uint8List nv21, int width, int height) {
    final int frameSize = width * height;
    final imglib.Image img = imglib.Image(width: width, height: height);
    int uvp = frameSize;
    int u = 0, v = 0;

    for (int j = 0, yp = 0; j < height; j++) {
      for (int i = 0; i < width; i++, yp++) {
        int y = (0xff & nv21[yp]) - 16;
        if (y < 0) y = 0;
        if ((i & 1) == 0) {
          v = (0xff & nv21[uvp++]) - 128;
          u = (0xff & nv21[uvp++]) - 128;
        }

        int r = (y + 1.370705 * v).round();
        int g = (y - 0.337633 * u - 0.698001 * v).round();
        int b = (y + 1.732446 * u).round();

        r = r.clamp(0, 255);
        g = g.clamp(0, 255);
        b = b.clamp(0, 255);

        // ARGB color where alpha is 255 (opaque)
        int color = (255 << 24) | (r << 16) | (g << 8) | b;
        img.setPixel(i, j, color as imglib.Color);
      }
    }

    return img;
  }

  // Convert BGRA8888 format image to imglib.Image
  static imglib.Image _convertBGRA8888(
      CameraImage image, CameraLensDirection direction) {
    final img = imglib.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: image.planes[0].bytes.buffer,
      format: imglib.Format.uint8,
    );

    // Rotate the image based on the camera lens direction
    return (direction == CameraLensDirection.front)
        ? imglib.copyRotate(img, angle: -90)
        : imglib.copyRotate(img, angle: 90);
  }

  // Convert YUV420 format image to imglib.Image
  static imglib.Image _convertYUV420(
      CameraImage image, CameraLensDirection direction) {
    final width = image.width;
    final height = image.height;
    final img = imglib.Image(width: width, height: height);
    const int hexFF = 0xFF000000;

    final uvyStride = image.planes[1].bytesPerRow;
    final uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        final uvIndex = uvPixelStride * (x ~/ 2) + uvyStride * (y ~/ 2);
        final index = y * width + x;

        final yp = image.planes[0].bytes[index];
        final up = image.planes[1].bytes[uvIndex];
        final vp = image.planes[2].bytes[uvIndex];

        int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
        int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
            .round()
            .clamp(0, 255);
        int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);

        // Set the pixel value in the image
        img.setPixel(x, y, (hexFF | (r << 16) | (g << 8) | b) as imglib.Color);
      }
    }

    // Rotate the image based on the camera lens direction
    return (direction == CameraLensDirection.front)
        ? imglib.copyRotate(img, angle: -90)
        : imglib.copyRotate(img, angle: 90);
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

class FaceDetectorPainter extends CustomPainter {
  FaceDetectorPainter(
    this.faces,
    this.imageSize,
    this.rotation,
    this.cameraLensDirection,
  );

  final List<Face> faces;
  final Size imageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint1 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.red;
    final Paint paint2 = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 1.0
      ..color = Colors.green;

    for (final Face face in faces) {
      final left = translateX(
        face.boundingBox.left,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final top = translateY(
        face.boundingBox.top,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final right = translateX(
        face.boundingBox.right,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final bottom = translateY(
        face.boundingBox.bottom,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );

      canvas.drawRect(
        Rect.fromLTRB(left, top, right, bottom),
        paint1,
      );

      void paintContour(FaceContourType type) {
        final contour = face.contours[type];
        if (contour?.points != null) {
          for (final Point point in contour!.points) {
            canvas.drawCircle(
                Offset(
                  translateX(
                    point.x.toDouble(),
                    size,
                    imageSize,
                    rotation,
                    cameraLensDirection,
                  ),
                  translateY(
                    point.y.toDouble(),
                    size,
                    imageSize,
                    rotation,
                    cameraLensDirection,
                  ),
                ),
                1,
                paint1);
          }
        }
      }

      void paintLandmark(FaceLandmarkType type) {
        final landmark = face.landmarks[type];
        if (landmark?.position != null) {
          canvas.drawCircle(
              Offset(
                translateX(
                  landmark!.position.x.toDouble(),
                  size,
                  imageSize,
                  rotation,
                  cameraLensDirection,
                ),
                translateY(
                  landmark.position.y.toDouble(),
                  size,
                  imageSize,
                  rotation,
                  cameraLensDirection,
                ),
              ),
              2,
              paint2);
        }
      }

      for (final type in FaceContourType.values) {
        paintContour(type);
      }

      for (final type in FaceLandmarkType.values) {
        paintLandmark(type);
      }
    }
  }

  @override
  bool shouldRepaint(FaceDetectorPainter oldDelegate) {
    return oldDelegate.imageSize != imageSize || oldDelegate.faces != faces;
  }
}

double translateX(
  double x,
  Size canvasSize,
  Size imageSize,
  InputImageRotation rotation,
  CameraLensDirection cameraLensDirection,
) {
  switch (rotation) {
    case InputImageRotation.rotation90deg:
      return x *
          canvasSize.width /
          (Platform.isIOS ? imageSize.width : imageSize.height);
    case InputImageRotation.rotation270deg:
      return canvasSize.width -
          x *
              canvasSize.width /
              (Platform.isIOS ? imageSize.width : imageSize.height);
    case InputImageRotation.rotation0deg:
    case InputImageRotation.rotation180deg:
      switch (cameraLensDirection) {
        case CameraLensDirection.back:
          return x * canvasSize.width / imageSize.width;
        default:
          return canvasSize.width - x * canvasSize.width / imageSize.width;
      }
  }
}

double translateY(
  double y,
  Size canvasSize,
  Size imageSize,
  InputImageRotation rotation,
  CameraLensDirection cameraLensDirection,
) {
  switch (rotation) {
    case InputImageRotation.rotation90deg:
    case InputImageRotation.rotation270deg:
      return y *
          canvasSize.height /
          (Platform.isIOS ? imageSize.height : imageSize.width);
    case InputImageRotation.rotation0deg:
    case InputImageRotation.rotation180deg:
      return y * canvasSize.height / imageSize.height;
  }
}
