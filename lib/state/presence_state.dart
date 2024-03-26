import 'package:flutter/material.dart';

class PresenceState with ChangeNotifier {
  bool _isPendingPresence = false;
  bool _isFailedSubmitApi = false;
  int _retrySubmitApi = 0;

  bool get isPendingPresence => _isPendingPresence;
  bool get isFailedSubmitApi => _isFailedSubmitApi;
  int get retrySubmitApi => _retrySubmitApi;

  // Private constructor
  PresenceState._();

  // Singleton instance
  static final PresenceState _instance = PresenceState._();

  // Getter method for the singleton instance
  static PresenceState get instance => _instance;

  set isPendingPresence(bool value) {
    _isPendingPresence = value;
    notifyListeners();
  }

  set isFailedSubmitApi(bool value) {
    _isFailedSubmitApi = value;
    notifyListeners();
  }

  set retrySubmitApi(int value) {
    _retrySubmitApi = value;
    notifyListeners();
  }
}
