import 'package:flutter/material.dart';

/// Pure black-and-white [ColorScheme] for surfaces, type, and controls.
///
/// Chromatic accent lives in [LinkvaultAccent] (gradients, glow, folder tints).
abstract final class LinkvaultMonochrome {
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightOnSurface = Color(0xFF000000);
  static const Color _darkSurface = Color(0xFF000000);
  static const Color _darkOnSurface = Color(0xFFFFFFFF);

  static ColorScheme scheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final surface = isDark ? _darkSurface : _lightSurface;
    final onSurface = isDark ? _darkOnSurface : _lightOnSurface;
    final container = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F5);
    final containerHigh = isDark ? const Color(0xFF141414) : const Color(0xFFEBEBEB);
    final containerHighest = isDark ? const Color(0xFF1C1C1C) : const Color(0xFFE0E0E0);
    final outline = isDark
        ? onSurface.withValues(alpha: 0.22)
        : onSurface.withValues(alpha: 0.14);

    return ColorScheme(
      brightness: brightness,
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
      error: isDark ? const Color(0xFFFF6B6B) : const Color(0xFFB00020),
      onError: _lightSurface,
      errorContainer: isDark ? const Color(0xFF2A1414) : const Color(0xFFFFE5E9),
      onErrorContainer: isDark ? const Color(0xFFFFB4B4) : const Color(0xFF5C0011),
      surface: surface,
      onSurface: onSurface,
      surfaceDim: isDark ? _darkSurface : const Color(0xFFF0F0F0),
      surfaceBright: isDark ? const Color(0xFF1A1A1A) : _lightSurface,
      surfaceContainerLowest: surface,
      surfaceContainerLow: container,
      surfaceContainer: containerHigh,
      surfaceContainerHigh: containerHighest,
      surfaceContainerHighest: isDark ? const Color(0xFF242424) : const Color(0xFFD6D6D6),
      onSurfaceVariant: isDark
          ? onSurface.withValues(alpha: 0.65)
          : onSurface.withValues(alpha: 0.55),
      outline: outline,
      outlineVariant: isDark
          ? onSurface.withValues(alpha: 0.12)
          : onSurface.withValues(alpha: 0.08),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: isDark ? _lightSurface : _darkSurface,
      onInverseSurface: isDark ? _lightOnSurface : _darkOnSurface,
      inversePrimary: isDark ? _darkOnSurface : _darkSurface,
    );
  }
}
