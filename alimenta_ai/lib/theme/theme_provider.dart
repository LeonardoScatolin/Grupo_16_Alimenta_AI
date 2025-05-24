import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const THEME_KEY = "theme_key";
  SharedPreferences? _prefs;
  bool _isDarkMode = false;
  bool _isInitialized = false;

  bool get isDarkMode => _isDarkMode;
  bool get isInitialized => _isInitialized;

  ThemeProvider() {
    _initializeTheme();
  }

  Future<void> _initializeTheme() async {
    await _initPrefs();
    await _loadFromPrefs();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> _loadFromPrefs() async {
    if (_prefs == null) await _initPrefs();
    _isDarkMode = _prefs?.getBool(THEME_KEY) ?? false;
  }

  Future<void> _saveToPrefs() async {
    if (_prefs == null) await _initPrefs();
    await _prefs?.setBool(THEME_KEY, _isDarkMode);
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _saveToPrefs();
    notifyListeners();
  }
}