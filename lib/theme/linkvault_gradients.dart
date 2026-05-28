import 'package:flutter/material.dart';

import 'app_motion.dart';

/// Ambient background gradients — use behind content only, not on cards.
abstract final class LinkvaultGradients {
  static bool enabled(BuildContext context) => motionEnabled(context);

  static Widget ambientLayer(
    BuildContext context, {
    double intensity = 1.0,
  }) {
    if (!enabled(context)) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryAlpha = (isDark ? 0.14 : 0.16) * intensity;
    final tertiaryAlpha = (isDark ? 0.10 : 0.12) * intensity;
    final secondaryAlpha = (isDark ? 0.06 : 0.08) * intensity;

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: _orb(
              size: 280,
              colors: [
                scheme.primary.withValues(alpha: primaryAlpha),
                scheme.primary.withValues(alpha: 0),
              ],
            ),
          ),
          Positioned(
            top: 120,
            left: -100,
            child: _orb(
              size: 240,
              colors: [
                scheme.tertiary.withValues(alpha: tertiaryAlpha),
                scheme.tertiary.withValues(alpha: 0),
              ],
            ),
          ),
          Positioned(
            bottom: -40,
            right: -20,
            child: _orb(
              size: 200,
              colors: [
                scheme.secondary.withValues(alpha: secondaryAlpha),
                scheme.secondary.withValues(alpha: 0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _orb({
    required double size,
    required List<Color> colors,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: colors),
      ),
    );
  }
}
