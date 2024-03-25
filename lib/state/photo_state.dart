import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PhotoState with ChangeNotifier {
  XFile? _pickedImage;
  XFile? get pickedImage => _pickedImage;

  PhotoState._();

  static final PhotoState _instance = PhotoState._();

  static PhotoState get instance => _instance;

  set pickedImage(XFile? value) {
    _pickedImage = value;
    notifyListeners();
  }
}
