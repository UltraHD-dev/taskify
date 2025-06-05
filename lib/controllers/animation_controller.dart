import 'package:flutter/material.dart';

class CustomAnimationController extends ChangeNotifier {
  bool _isLoading = false;
  bool _isAnimating = false;

  bool get isLoading => _isLoading;
  bool get isAnimating => _isAnimating;

  void startLoading() {
    _isLoading = true;
    notifyListeners();
  }

  void stopLoading() {
    _isLoading = false;
    notifyListeners();
  }

  void startAnimation() {
    _isAnimating = true;
    notifyListeners();
  }

  void stopAnimation() {
    _isAnimating = false;
    notifyListeners();
  }
}