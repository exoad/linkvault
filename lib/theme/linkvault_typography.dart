import 'package:flutter/material.dart';

import 'linkvault_design.dart';

/// Plus Jakarta Sans text styles for Linkvault.
abstract final class LinkvaultTypography {
  static const String fontFamily = LinkvaultDesign.fontFamily;

  static TextTheme textTheme(ColorScheme scheme) {
    final base = TextTheme(
      displayLarge: _style(57, FontWeight.w600, 64, scheme.onSurface),
      displayMedium: _style(45, FontWeight.w600, 52, scheme.onSurface),
      displaySmall: _style(36, FontWeight.w600, 44, scheme.onSurface),
      headlineLarge: _style(32, FontWeight.w600, 40, scheme.onSurface),
      headlineMedium: _style(28, FontWeight.w600, 36, scheme.onSurface),
      headlineSmall: _style(24, FontWeight.w600, 32, scheme.onSurface),
      titleLarge: _style(22, FontWeight.w600, 28, scheme.onSurface),
      titleMedium: _style(18, FontWeight.w500, 24, scheme.onSurface),
      titleSmall: _style(14, FontWeight.w500, 20, scheme.onSurface),
      bodyLarge: _style(16, FontWeight.w400, 24, scheme.onSurface),
      bodyMedium: _style(14, FontWeight.w400, 20, scheme.onSurface),
      bodySmall: _style(12, FontWeight.w400, 16, scheme.onSurfaceVariant),
      labelLarge: _style(14, FontWeight.w500, 20, scheme.onSurface),
      labelMedium: _style(12, FontWeight.w500, 16, scheme.onSurfaceVariant),
      labelSmall: _style(11, FontWeight.w500, 16, scheme.onSurfaceVariant),
    );
    return base.apply(fontFamily: fontFamily);
  }

  static TextStyle _style(
    double size,
    FontWeight weight,
    double height,
    Color color,
  ) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      height: height / size,
      letterSpacing: size >= 18 ? -0.2 : 0,
      color: color,
    );
  }

  /// Section headers in settings and grouped lists.
  static TextStyle sectionLabel(ColorScheme scheme) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 13,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
      color: scheme.onSurfaceVariant,
    );
  }

  /// URLs and secondary metadata.
  static TextStyle meta(ColorScheme scheme) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.35,
      letterSpacing: 0.15,
      color: scheme.onSurfaceVariant,
    );
  }
}
