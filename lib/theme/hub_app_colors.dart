import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../hub/hub_module.dart';
import 'linkvault_accent.dart';

/// Living colors for hub apps — subtle blends with the global edge-glow cycle.
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

    return HubAppPalette(
      primary: primary,
      secondary: secondary,
      tertiary: secondary,
      glow: primary.withValues(alpha: 0.1),
    );
  }

  static Color _living({
    required LinkvaultAccent accent,
    required Color seed,
    required double phase,
    required double offset,
  }) {
    final cycle = accent.cycleColor(phase + offset);
    final blend = 0.34 + 0.22 * _wave(phase + offset * 1.7);
    return Color.lerp(seed, cycle, blend)!;
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
}
