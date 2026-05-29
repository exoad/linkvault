import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Legacy appearance preferences (edge glow index, seed color).
class ThemePreferences {
  static const _edgeGlowIndexKey = 'edge_glow_index';
  static const _seedColorKey = 'seed_color_argb';

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
