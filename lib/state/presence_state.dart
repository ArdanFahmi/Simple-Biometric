import 'package:flutter/material.dart';

class PresenceState with ChangeNotifier {
  bool _isPendingPresence = false;
  bool get isPendingPresence => _isPendingPresence;

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
}
