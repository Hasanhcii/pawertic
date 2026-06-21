import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ChangeNotifier {
  static bool isDarkMode = true;

  ThemeNotifier() {
    _loadFromPrefs();
  }

  void _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkMode = prefs.getBool('isDarkMode') ?? true;
    notifyListeners();
  }

  void toggle() async { 
    isDarkMode = !isDarkMode; 
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
    notifyListeners(); 
  }
}

final themeNotifier = ThemeNotifier();
