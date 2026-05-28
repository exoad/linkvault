import 'package:flutter/material.dart';

/// Linkvault visual tokens: flat surfaces, hairline borders, expressive scale.
///
/// Gradients belong in the background layer only ([LinkvaultGradients]);
/// cards use solid [surfaceDecoration].
abstract final class LinkvaultDesign {
  static const String fontFamily = 'PlusJakartaSans';

  static const double radiusSm = 10;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusHero = 28;

  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 12;
  static const double spaceLg = 16;
  static const double spaceXl = 24;
  static const double space2xl = 32;

  static const double borderWidth = 1;

  static Border border(ColorScheme scheme) => Border.all(
        color: scheme.outlineVariant.withValues(alpha: 0.55),
        width: borderWidth,
      );

  static Border accentBorder(ColorScheme scheme) => Border.all(
        color: scheme.primary.withValues(alpha: 0.35),
        width: borderWidth,
      );

  static BorderRadius get radiusCard => BorderRadius.circular(radiusLg);
  static BorderRadius get radiusControl => BorderRadius.circular(radiusMd);
  static BorderRadius get radiusSheet => BorderRadius.circular(radiusXl);
  static BorderRadius get radiusHeroCard => BorderRadius.circular(radiusHero);

  static BoxDecoration surfaceDecoration(
    ColorScheme scheme, {
    Color? color,
    BorderRadius? borderRadius,
    bool accent = false,
  }) {
    return BoxDecoration(
      color: color ?? scheme.surfaceContainerLow,
      border: accent ? accentBorder(scheme) : border(scheme),
      borderRadius: borderRadius ?? radiusCard,
    );
  }
}
