import 'package:flutter/material.dart';

class BiometricAuthState with ChangeNotifier {
  String _returnAuthorized = "Not Authorized";
  String get returnAuthorized => _returnAuthorized;

  BiometricAuthState._();

  static final BiometricAuthState _instance = BiometricAuthState._();

  static BiometricAuthState get instance => _instance;

  set returnAuthorized(String value) {
    _returnAuthorized = value;
    notifyListeners();
  }
}
