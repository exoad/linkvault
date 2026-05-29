import 'package:flutter/material.dart';

/// Pure black-and-white [ColorScheme] for surfaces, type, and controls.
///
/// Chromatic accent lives in [LinkvaultAccent] (gradients, glow, folder tints).
abstract final class LinkvaultMonochrome {
  static const Color _darkSurface = Color(0xFF000000);
  static const Color _darkOnSurface = Color(0xFFFFFFFF);

  /// The only supported app appearance (dark).
  static ColorScheme get dark => scheme(Brightness.dark);

  static ColorScheme scheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    assert(isDark, 'Linkvault only supports dark mode');
    const surface = _darkSurface;
    const onSurface = _darkOnSurface;
    const container = Color(0xFF0A0A0A);
    const containerHigh = Color(0xFF141414);
    const containerHighest = Color(0xFF1C1C1C);
    final outline = onSurface.withValues(alpha: 0.22);

    return ColorScheme(
      brightness: Brightness.dark,
      primary: onSurface,
      onPrimary: surface,
      primaryContainer: containerHigh,
      onPrimaryContainer: onSurface,
      secondary: onSurface,
      onSecondary: surface,
      secondaryContainer: container,
      onSecondaryContainer: onSurface,
      tertiary: onSurface,
      onTertiary: surface,
      tertiaryContainer: container,
      onTertiaryContainer: onSurface,
      error: const Color(0xFFFF6B6B),
      onError: Colors.white,
      errorContainer: const Color(0xFF2A1414),
      onErrorContainer: const Color(0xFFFFB4B4),
      surface: surface,
      onSurface: onSurface,
      surfaceDim: _darkSurface,
      surfaceBright: const Color(0xFF1A1A1A),
      surfaceContainerLowest: surface,
      surfaceContainerLow: container,
      surfaceContainer: containerHigh,
      surfaceContainerHigh: containerHighest,
      surfaceContainerHighest: const Color(0xFF242424),
      onSurfaceVariant: onSurface.withValues(alpha: 0.65),
      outline: outline,
      outlineVariant: onSurface.withValues(alpha: 0.12),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: Colors.white,
      onInverseSurface: Colors.black,
      inversePrimary: _darkOnSurface,
    );
  }
}
