import 'package:flutter/material.dart';

import 'edge_glow_palette.dart';
import 'linkvault_accent.dart';

/// Auto-cycling chroma for the lava-lamp ambient and living UI tints.
///
/// Colors are drawn from all curated [EdgeGlowPalette] hues and lerped in a
/// loop so the background and accents evolve without a user picker.
abstract final class AmbientLavaPalette {
  static final List<Color> _colors = [
    for (final preset in EdgeGlowPalette.presets) ...[
      preset.primary,
      preset.secondary,
      preset.tertiary,
    ],
  ];

  static int get length => _colors.length;

  /// Smoothly cycles through the full palette for [phase] in any range.
  static Color colorAt(double phase) {
    if (_colors.isEmpty) return const Color(0xFF6B9FFF);
    final wrapped = ((phase % 1.0) + 1.0) % 1.0;
    final p = wrapped * _colors.length;
    final index = p.floor() % _colors.length;
    final next = (index + 1) % _colors.length;
    return Color.lerp(_colors[index], _colors[next], p - p.floor())!;
  }

  /// Three staggered palette samples for [LinkvaultAccent] theme registration.
  static LinkvaultAccent accentTriplet(double phase) {
    return LinkvaultAccent(
      primary: colorAt(phase),
      secondary: colorAt(phase + 0.33),
      tertiary: colorAt(phase + 0.66),
    );
  }

  /// Static accent for [MaterialApp] theme shell (widgets with phase use [colorAt]).
  static LinkvaultAccent get defaultAccent => accentTriplet(0);
}
