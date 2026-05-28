import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../hub/hub_module.dart';
import 'linkvault_accent.dart';

/// Living colors for hub apps — blends app seeds with the global edge-glow cycle.
abstract final class HubAppColors {
  static HubAppPalette palette(
    LinkvaultAccent accent,
    HubAppDefinition app,
    double phase,
  ) {
    final p = phase + app.phaseOffset;
    final primary = _living(
      accent: accent,
      seed: app.seedPrimary,
      phase: p,
      offset: 0.0,
    );
    final secondary = _living(
      accent: accent,
      seed: app.seedSecondary,
      phase: p,
      offset: 0.33,
    );
    final tertiary = _living(
      accent: accent,
      seed: Color.lerp(app.seedPrimary, app.seedSecondary, 0.5)!,
      phase: p,
      offset: 0.66,
    );
    final glow = primary.withValues(
      alpha: 0.28 + 0.1 * _wave(p + 0.2),
    );

    return HubAppPalette(
      primary: primary,
      secondary: secondary,
      tertiary: tertiary,
      glow: glow,
    );
  }

  static Color _living({
    required LinkvaultAccent accent,
    required Color seed,
    required double phase,
    required double offset,
  }) {
    final cycle = _cycleAccent(accent, phase + offset);
    final blend = 0.38 + 0.28 * _wave(phase + offset * 1.7);
    return Color.lerp(seed, cycle, blend)!;
  }

  static Color _cycleAccent(LinkvaultAccent accent, double phase) {
    final colors = [accent.primary, accent.secondary, accent.tertiary];
    final p = (phase % 1.0) * colors.length;
    final index = p.floor() % colors.length;
    final next = (index + 1) % colors.length;
    return Color.lerp(colors[index], colors[next], p - p.floor())!;
  }

  static double _wave(double phase) => math.sin(phase * math.pi * 2);
}

@immutable
class HubAppPalette {
  const HubAppPalette({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.glow,
  });

  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color glow;

  List<Color> get gradient => [primary, secondary, tertiary];
}
