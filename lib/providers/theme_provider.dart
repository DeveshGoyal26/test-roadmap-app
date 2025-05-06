import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'isDarkMode';
  static const String _useSystemThemeKey = 'useSystemTheme';
  bool _isDarkMode = false;
  bool _useSystemTheme = true;
  late SharedPreferences _prefs;

  bool get isDarkMode => _isDarkMode;
  bool get useSystemTheme => _useSystemTheme;

  // Initialize theme provider
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Check if we should use system theme
    _useSystemTheme = _prefs.getBool(_useSystemThemeKey) ?? true;
    
    if (_useSystemTheme) {
      _updateThemeFromSystem();
    } else {
      // Use saved theme preference
      _isDarkMode = _prefs.getBool(_themeKey) ?? false;
    }
    
    // Listen to system theme changes
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged = () {
      if (_useSystemTheme) {
        _updateThemeFromSystem();
      }
    };
    
    notifyListeners();
  }

  void _updateThemeFromSystem() {
    var brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    _isDarkMode = brightness == Brightness.dark;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _useSystemTheme = false;
    _isDarkMode = !_isDarkMode;
    // Save the theme preference and system theme setting
    await _prefs.setBool(_themeKey, _isDarkMode);
    await _prefs.setBool(_useSystemThemeKey, false);
    notifyListeners();
  }

  Future<void> setUseSystemTheme(bool value) async {
    _useSystemTheme = value;
    await _prefs.setBool(_useSystemThemeKey, value);
    
    if (value) {
      _updateThemeFromSystem();
    }
    notifyListeners();
  }
}