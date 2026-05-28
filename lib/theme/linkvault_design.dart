import 'package:flutter/material.dart';

/// Linkvault visual tokens: flat surfaces, hairline borders, geometric type.
///
/// Depth comes from tonal [ColorScheme] steps, not elevation or shadows.
abstract final class LinkvaultDesign {
  static const String fontFamily = 'PlusJakartaSans';

  static const double radiusSm = 10;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;

  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 12;
  static const double spaceLg = 16;
  static const double spaceXl = 24;

  static const double borderWidth = 1;

  static Border border(ColorScheme scheme) => Border.all(
        color: scheme.outlineVariant.withValues(alpha: 0.55),
        width: borderWidth,
      );

  static BorderRadius get radiusCard => BorderRadius.circular(radiusLg);
  static BorderRadius get radiusControl => BorderRadius.circular(radiusMd);
  static BorderRadius get radiusSheet => BorderRadius.circular(radiusXl);

  static BoxDecoration surfaceDecoration(
    ColorScheme scheme, {
    Color? color,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: color ?? scheme.surfaceContainerLow,
      border: border(scheme),
      borderRadius: borderRadius ?? radiusCard,
    );
  }
}
