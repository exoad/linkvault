import 'package:flutter/material.dart';

import 'linkvault_design.dart';

/// Plus Jakarta Sans text styles for Linkvault.
abstract final class LinkvaultTypography {
  static const String fontFamily = LinkvaultDesign.fontFamily;

  static TextTheme textTheme(ColorScheme scheme) {
    final base = TextTheme(
      displayLarge: _style(57, FontWeight.w700, 64, scheme.onSurface),
      displayMedium: _style(45, FontWeight.w700, 52, scheme.onSurface),
      displaySmall: _style(36, FontWeight.w700, 44, scheme.onSurface),
      headlineLarge: _style(32, FontWeight.w700, 40, scheme.onSurface),
      headlineMedium: _style(28, FontWeight.w700, 36, scheme.onSurface),
      headlineSmall: _style(24, FontWeight.w600, 32, scheme.onSurface),
      titleLarge: _style(22, FontWeight.w600, 28, scheme.onSurface),
      titleMedium: _style(18, FontWeight.w600, 24, scheme.onSurface),
      titleSmall: _style(14, FontWeight.w600, 20, scheme.onSurface),
      bodyLarge: _style(16, FontWeight.w400, 24, scheme.onSurface),
      bodyMedium: _style(14, FontWeight.w400, 20, scheme.onSurface),
      bodySmall: _style(12, FontWeight.w400, 16, scheme.onSurfaceVariant),
      labelLarge: _style(14, FontWeight.w600, 20, scheme.onSurface),
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
      letterSpacing: size >= 22 ? -0.4 : (size >= 18 ? -0.2 : 0),
      color: color,
    );
  }

  /// Home hub hero title.
  static TextStyle hubTitle(ColorScheme scheme) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 38,
      fontWeight: FontWeight.w700,
      height: 1.1,
      letterSpacing: -0.6,
      color: scheme.onSurface,
    );
  }

  /// Hero subtitle and section intros.
  static TextStyle hubSubtitle(ColorScheme scheme) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.35,
      letterSpacing: -0.1,
      color: scheme.onSurfaceVariant,
    );
  }

  /// Section headers in settings and grouped lists.
  static TextStyle sectionLabel(ColorScheme scheme) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 13,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
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
