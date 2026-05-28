import 'package:flutter/material.dart';

import 'linkvault_accent.dart';

/// Curated edge-glow accents — bright but soft, not wallpaper-based.
@immutable
class EdgeGlowPreset {
  const EdgeGlowPreset({
    required this.name,
    required this.primary,
    required this.secondary,
    required this.tertiary,
  });

  final String name;
  final Color primary;
  final Color secondary;
  final Color tertiary;

  LinkvaultAccent toAccent() => LinkvaultAccent(
        primary: primary,
        secondary: secondary,
        tertiary: tertiary,
      );
}

abstract final class EdgeGlowPalette {
  static const presets = <EdgeGlowPreset>[
    EdgeGlowPreset(
      name: 'Aurora',
      primary: Color(0xFF6B9FFF),
      secondary: Color(0xFFFF8FAB),
      tertiary: Color(0xFF5ED4B8),
    ),
    EdgeGlowPreset(
      name: 'Ocean',
      primary: Color(0xFF4DA8FF),
      secondary: Color(0xFF38BDF8),
      tertiary: Color(0xFF34D399),
    ),
    EdgeGlowPreset(
      name: 'Sunset',
      primary: Color(0xFFFF9F6B),
      secondary: Color(0xFFFFB347),
      tertiary: Color(0xFFE8789A),
    ),
    EdgeGlowPreset(
      name: 'Bloom',
      primary: Color(0xFFA78BFA),
      secondary: Color(0xFFF472B6),
      tertiary: Color(0xFFFBBF24),
    ),
    EdgeGlowPreset(
      name: 'Citrus',
      primary: Color(0xFFFCD34D),
      secondary: Color(0xFFFB923C),
      tertiary: Color(0xFF4ADE80),
    ),
    EdgeGlowPreset(
      name: 'Twilight',
      primary: Color(0xFF818CF8),
      secondary: Color(0xFF22D3EE),
      tertiary: Color(0xFFF9A8D4),
    ),
  ];

  static const int defaultIndex = 0;

  static EdgeGlowPreset presetAt(int index) =>
      presets[index.clamp(0, presets.length - 1)];

  static LinkvaultAccent accentAt(int index) => presetAt(index).toAccent();

  /// Maps a legacy stored ARGB to the nearest preset for migration.
  static int indexForColor(Color color) {
    var best = 0;
    var bestDist = double.maxFinite;
    for (var i = 0; i < presets.length; i++) {
      final p = presets[i].primary;
      final d = _dist(color, p);
      if (d < bestDist) {
        bestDist = d;
        best = i;
      }
    }
    return best;
  }

  static double _dist(Color a, Color b) {
    final ar = a.r * 255, ag = a.g * 255, ab = a.b * 255;
    final br = b.r * 255, bg = b.g * 255, bb = b.b * 255;
    return (ar - br) * (ar - br) + (ag - bg) * (ag - bg) + (ab - bb) * (ab - bb);
  }
}
