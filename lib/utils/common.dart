import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:crypto/crypto.dart';

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
