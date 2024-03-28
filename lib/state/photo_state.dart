import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PhotoState with ChangeNotifier {
  XFile? _pickedImage;
  bool _isFormRegister = false;

  XFile? get pickedImage => _pickedImage;
  bool get isFormRegister => _isFormRegister;

  PhotoState._();

  static final PhotoState _instance = PhotoState._();

  static PhotoState get instance => _instance;

  set pickedImage(XFile? value) {
    _pickedImage = value;
    notifyListeners();
  }

  set isFormRegister(bool value) {
    _isFormRegister = value;
    notifyListeners();
  }

  // ignore: must_call_super, annotate_overrides
  void dispose() {
    _pickedImage = null;
  }
}
