import 'package:flutter/material.dart';

/// Chromatic accent used for edge gradients and glow — not for base UI chrome.
@immutable
class LinkvaultAccent extends ThemeExtension<LinkvaultAccent> {
  const LinkvaultAccent({
    required this.primary,
    required this.secondary,
    required this.tertiary,
  });

  final Color primary;
  final Color secondary;
  final Color tertiary;

  factory LinkvaultAccent.fromSeed({
    required Color seedColor,
    required Brightness brightness,
  }) {
    final colorful = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.expressive,
    );
    return LinkvaultAccent(
      primary: colorful.primary,
      secondary: colorful.secondary,
      tertiary: colorful.tertiary,
    );
  }

  factory LinkvaultAccent.fromColorScheme(ColorScheme scheme) {
    return LinkvaultAccent(
      primary: scheme.primary,
      secondary: scheme.secondary,
      tertiary: scheme.tertiary,
    );
  }

  @override
  LinkvaultAccent copyWith({
    Color? primary,
    Color? secondary,
    Color? tertiary,
  }) {
    return LinkvaultAccent(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      tertiary: tertiary ?? this.tertiary,
    );
  }

  @override
  LinkvaultAccent lerp(LinkvaultAccent? other, double t) {
    if (other == null) return this;
    return LinkvaultAccent(
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      tertiary: Color.lerp(tertiary, other.tertiary, t)!,
    );
  }
}

extension LinkvaultAccentContext on BuildContext {
  LinkvaultAccent get linkvaultAccent =>
      Theme.of(this).extension<LinkvaultAccent>()!;
}

extension LinkvaultAccentCycle on LinkvaultAccent {
  /// Smoothly cycles primary → secondary → tertiary → primary for a phase in
  /// any range. Used for the living edge glow, hub tiles, and surface tints.
  Color cycleColor(double phase) {
    final colors = [primary, secondary, tertiary];
    final wrapped = ((phase % 1.0) + 1.0) % 1.0;
    final p = wrapped * colors.length;
    final index = p.floor() % colors.length;
    final next = (index + 1) % colors.length;
    return Color.lerp(colors[index], colors[next], p - p.floor())!;
  }
}
