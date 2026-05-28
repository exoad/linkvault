import 'package:flutter/material.dart';

/// Linkvault visual tokens. Surfaces use tone only — no hairline boxes by default.
abstract final class LinkvaultDesign {
  static const String fontFamily = 'PlusJakartaSans';

  static const double radiusSm = 10;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusHero = 28;

  /// Fully rounded ends for buttons and FABs.
  static const double radiusPill = 999;

  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 12;
  static const double spaceLg = 16;
  static const double spaceXl = 24;
  static const double space2xl = 32;

  static BoxDecoration surfaceDecoration(
    ColorScheme scheme, {
    Color? color,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: color ?? scheme.surfaceContainerLow,
      borderRadius: borderRadius ?? radiusCard,
    );
  }

  static BorderRadius get radiusCard => BorderRadius.circular(radiusLg);
  static BorderRadius get radiusControl => BorderRadius.circular(radiusMd);
  static BorderRadius get radiusSheet => BorderRadius.circular(radiusXl);
  static BorderRadius get radiusHeroCard => BorderRadius.circular(radiusHero);
  static BorderRadius get radiusButton => BorderRadius.circular(radiusPill);
  static StadiumBorder get buttonShape => const StadiumBorder();
}
