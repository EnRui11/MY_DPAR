import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService with ChangeNotifier {
  // Available languages
  static const String english = 'en';
  static const String malay = 'ms';
  static const String mandarin = 'zh';
  
  // Default language
  String _currentLanguage = english;
  
  // Getter for current language
  String get currentLanguage => _currentLanguage;
  
  // Getter for current language code display
  String get currentLanguageCode {
    switch (_currentLanguage) {
      case english:
        return 'EN';
      case malay:
        return 'BM';
      case mandarin:
        return 'ZH';
      default:
        return 'EN';
    }
  }
  
  // Constructor loads saved language preference
  LanguageService() {
    _loadSavedLanguage();
  }
  
  // Load saved language from SharedPreferences
  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('language');
    if (savedLanguage != null) {
      _currentLanguage = savedLanguage;
      notifyListeners();
    }
  }
  
  // Change language and save preference
  Future<void> changeLanguage(String languageCode) async {
    if (_currentLanguage != languageCode) {
      _currentLanguage = languageCode;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', languageCode);
      notifyListeners();
    }
  }
  
  // Get full language name from code
  String getLanguageName(String code) {
    switch (code) {
      case english:
        return 'English';
      case malay:
        return 'Bahasa Melayu';
      case mandarin:
        return '中文';
      default:
        return 'English';
    }
  }
}