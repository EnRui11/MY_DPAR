import 'package:flutter/material.dart';
import 'package:mydpar/theme/color_theme.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  // Return an instance of AppColorTheme
  AppColorTheme get currentTheme =>
      _isDarkMode ? AppColors.dark : AppColors.light;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}
