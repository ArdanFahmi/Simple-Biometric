import 'package:flutter/material.dart';

class InternetState with ChangeNotifier {
  bool _isConnectInternet = true;
  bool get isConnectInternet => _isConnectInternet;

  // Private constructor
  InternetState._();

  // Singleton instance
  static final InternetState _instance = InternetState._();

  // Getter method for the singleton instance
  static InternetState get instance => _instance;

  set isConnectInternet(bool value) {
    _isConnectInternet = value;
    notifyListeners();
  }
}
