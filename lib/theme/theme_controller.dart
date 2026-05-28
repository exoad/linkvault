import 'package:flutter/material.dart';

import '../services/theme_preferences.dart';
import 'edge_glow_palette.dart';
import 'linkvault_accent.dart';

class ThemeController extends ChangeNotifier {
  ThemeController({ThemePreferences? preferences})
      : _preferences = preferences ?? ThemePreferences();

  final ThemePreferences _preferences;

  ThemeMode _themeMode = ThemeMode.system;
  int _edgeGlowIndex = EdgeGlowPalette.defaultIndex;

  ThemeMode get themeMode => _themeMode;
  int get edgeGlowIndex => _edgeGlowIndex;
  EdgeGlowPreset get edgeGlowPreset => EdgeGlowPalette.presetAt(_edgeGlowIndex);
  LinkvaultAccent get accent => edgeGlowPreset.toAccent();

  Future<void> load() async {
    _themeMode = await _preferences.getThemeMode();
    final storedIndex = await _preferences.getEdgeGlowIndex();
    if (storedIndex != null) {
      _edgeGlowIndex = storedIndex;
    } else {
      final legacy = await _preferences.getLegacySeedColor();
      if (legacy != null) {
        _edgeGlowIndex = EdgeGlowPalette.indexForColor(legacy);
      }
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _preferences.setThemeMode(mode);
    notifyListeners();
  }

  Future<void> setEdgeGlowIndex(int index) async {
    _edgeGlowIndex = index.clamp(0, EdgeGlowPalette.presets.length - 1);
    await _preferences.setEdgeGlowIndex(_edgeGlowIndex);
    notifyListeners();
  }
}
