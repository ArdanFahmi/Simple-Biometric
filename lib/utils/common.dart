import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:intl/intl.dart';
import 'package:crypto/crypto.dart';
import 'dart:math' show cos, sqrt, asin, pow;
import 'package:image/image.dart' as imglib;
import 'dart:ui' as ui;

String getCurrentDateFormatted() {
  final now = DateTime.now();
  final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
  return formatter.format(now);
}

String getTimestamp() {
  DateTime now = DateTime.now();
  int millisecondsSinceEpoch = now.millisecondsSinceEpoch;
  return millisecondsSinceEpoch.toString();
}

void showSnackbar(BuildContext ctx, String msg, Color color) {
  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
    content: Text(msg),
    backgroundColor: color,
    behavior: SnackBarBehavior.floating,
  ));
}

String calculateMD5(String input) {
  List<int> bytes = utf8.encode(input);
  Digest md5Digest = md5.convert(bytes);

  return md5Digest.toString();
}

String getDateFormattedToken() {
  final now = DateTime.now();
  final formatter = DateFormat('yyyy-MM-dd HH');
  return formatter.format(now);
}

double calculateDistance(lat1, lon1, lat2, lon2) {
  var p = 0.017453292519943295;
  var c = cos;
  var a = 0.5 -
      c((lat2 - lat1) * p) / 2 +
      c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
  return 1000 * 12742 * asin(sqrt(a)); //return meters
}

bool isInRadius(double location) {
  if (location > 50) {
    return false;
  } else {
    return true;
  }
}

imglib.Image? cropToBox(imglib.Image image, Rect boundingBox, int rotation) {
  imglib.Image croppedImage = image;

  // Handle rotation
  if (rotation != 0) {
    // Rotate the image
    croppedImage = imglib.copyRotate(image, angle: rotation);
  }

  // Check bounds
  if (boundingBox.top >= 0 &&
      boundingBox.bottom <= croppedImage.width &&
      boundingBox.top + boundingBox.height <= croppedImage.height &&
      boundingBox.left >= 0 &&
      boundingBox.left + boundingBox.width <= croppedImage.width) {
    // Crop the image
    return imglib.copyCrop(croppedImage,
        x: boundingBox.left.toInt(),
        y: boundingBox.right.toInt(),
        width: boundingBox.width.toInt(),
        height: boundingBox.height.toInt());
  } else {
    return null; // Out of bounds
  }
}

Float32List imageToByteListFloat32(
    imglib.Image image, int inputSize, double mean, double std) {
  var convertedBytes = Float32List(inputSize * inputSize * 3);
  var buffer = Float32List.view(convertedBytes.buffer);
  int pixelIndex = 0;

  for (var i = 0; i < inputSize; i++) {
    for (var j = 0; j < inputSize; j++) {
      var pixel = image.getPixel(j, i);
      buffer[pixelIndex++] = (pixel[0] - mean) / std; //r
      buffer[pixelIndex++] = (pixel[1] - mean) / std; //g
      buffer[pixelIndex++] = (pixel[1] - mean) / std; //b
    }
  }

  return convertedBytes.buffer.asFloat32List();
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

String compareExistSavedFaces(List currEmb, List localEmb) {
  double minDist = 999;
  double currDist = 0.0;
  double threshold = 1.0;
  String predRes = "NOT RECOGNIZED";
  currDist = euclideanDistance(currEmb, localEmb);
  if (currDist <= threshold && currDist < minDist) {
    minDist = currDist;
  }
  // for (String label in data.keys) {
  //   currDist = euclideanDistance(currEmb, currEmb);
  //   if (currDist <= threshold && currDist < minDist) {
  //     minDist = currDist;
  //     predRes = label;
  //   }
  // }
  print("result distance "+currDist.toString() + " ");
  return predRes;
}

double euclideanDistance(List e1, List e2) {
  double sum = 0.0;
  for (int i = 0; i < e1.length; i++) {
    sum += pow((e1[i] - e2[i]), 2);
  }
  return sqrt(sum);
}

imglib.Image nv21ToImage(CameraImage cameraImage) {
  final width = cameraImage.width;
  final height = cameraImage.height;

  // Create an Image object
  final imgImage = imglib.Image(width: width, height: height);

  // NV21 conversion logic
  final yPlane = cameraImage.planes[0].bytes;
  final uvPlane = cameraImage.planes[1].bytes;

  int yIndex = 0;
  int uvIndex = 0;

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final yValue = yPlane[yIndex] & 0xFF;
      final uValue = uvPlane[uvIndex] & 0xFF;
      final vValue = uvPlane[uvIndex + 1] & 0xFF;

      // YUV to RGB conversion
      final r = (yValue + 1.403 * (vValue - 128)).clamp(0, 255).toInt();
      final g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128))
          .clamp(0, 255)
          .toInt();
      final b = (yValue + 1.772 * (uValue - 128)).clamp(0, 255).toInt();

      imgImage.setPixel(x, y, imgImage.getColor(r, g, b));

      yIndex++;
      if (x % 2 == 1 && y % 2 == 1) {
        uvIndex += 2;
      }
    }
  }

  return imgImage;
}

imglib.Image decodeYUV420SP(InputImage image) {
  final width = image.metadata!.size.width.toInt();
  final height = image.metadata!.size.height.toInt();

  final yuv420sp = image.bytes!;
  // The math for converting YUV to RGB below assumes you're
  // putting the RGB into a uint32. To simplify and keep the
  // code as it is, make a 4-channel Image, get the image data bytes,
  // and view it at a Uint32List. This is the equivalent to the image
  // data of the 3.x version of the Image library. It does waste some
  // memory, the alpha channel isn't used, but it simplifies the math.
  final outImg = imglib.Image(width: width, height: height, numChannels: 4);
  final outBytes = outImg.getBytes();
  // View the image data as a Uint32List.
  final rgba = Uint32List.view(outBytes.buffer);

  final frameSize = width * height;

  for (var j = 0, yp = 0; j < height; j++) {
    var uvp = frameSize + (j >> 1) * width;
    var u = 0;
    var v = 0;
    for (int i = 0; i < width; i++, yp++) {
      var y = (0xff & (yuv420sp[yp])) - 16;
      if (y < 0) {
        y = 0;
      }
      if ((i & 1) == 0) {
        v = (0xff & yuv420sp[uvp++]) - 128;
        u = (0xff & yuv420sp[uvp++]) - 128;
      }

      final y1192 = 1192 * y;
      var r = (y1192 + 1634 * v);
      var g = (y1192 - 833 * v - 400 * u);
      var b = (y1192 + 2066 * u);

      if (r < 0) {
        r = 0;
      } else if (r > 262143) {
        r = 262143;
      }
      if (g < 0) {
        g = 0;
      } else if (g > 262143) {
        g = 262143;
      }
      if (b < 0) {
        b = 0;
      } else if (b > 262143) {
        b = 262143;
      }

      // Write directly into the image data
      rgba[yp] = 0xff000000 |
          ((b << 6) & 0xff0000) |
          ((g >> 2) & 0xff00) |
          ((r >> 10) & 0xff);
    }
  }

  // Rotate the image so it's the correct oreintation.
  return imglib.copyRotate(outImg, angle: 90);
}
