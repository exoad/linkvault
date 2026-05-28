import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemePreferences {
  static const _themeModeKey = 'theme_mode';
  static const _edgeGlowIndexKey = 'edge_glow_index';
  static const _seedColorKey = 'seed_color_argb';

  Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_themeModeKey);
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await prefs.setString(_themeModeKey, stored);
  }

  Future<int?> getEdgeGlowIndex() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_edgeGlowIndexKey)) return null;
    return prefs.getInt(_edgeGlowIndexKey);
  }

  Future<void> setEdgeGlowIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_edgeGlowIndexKey, index);
  }

  /// Legacy seed color from before preset-based glow.
  Future<Color?> getLegacySeedColor() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_seedColorKey)) return null;
    return Color(prefs.getInt(_seedColorKey)!);
  }
}
