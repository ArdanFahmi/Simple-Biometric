import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:crypto/crypto.dart';
import 'dart:math' show cos, sqrt, asin;

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
