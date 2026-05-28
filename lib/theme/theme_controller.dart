import 'package:flutter/material.dart';

import '../models/folder.dart';
import '../services/theme_preferences.dart';

class ThemeController extends ChangeNotifier {
  ThemeController({ThemePreferences? preferences})
      : _preferences = preferences ?? ThemePreferences();

  final ThemePreferences _preferences;

  ThemeMode _themeMode = ThemeMode.system;
  bool _useDynamicColor = true;
  Color _seedColor = const Color(FolderModel.defaultColorValue);

  ThemeMode get themeMode => _themeMode;
  bool get useDynamicColor => _useDynamicColor;
  Color get seedColor => _seedColor;

  Future<void> load() async {
    _themeMode = await _preferences.getThemeMode();
    _useDynamicColor = await _preferences.getUseDynamicColor();
    final storedSeed = await _preferences.getSeedColor();
    if (storedSeed != null) _seedColor = storedSeed;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _preferences.setThemeMode(mode);
    notifyListeners();
  }

  Future<void> setUseDynamicColor(bool value) async {
    _useDynamicColor = value;
    await _preferences.setUseDynamicColor(value);
    notifyListeners();
  }

  Future<void> setSeedColor(Color color) async {
    _seedColor = color;
    await _preferences.setSeedColor(color);
    notifyListeners();
  }
}
