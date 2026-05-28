import 'package:flutter/material.dart';

import '../widgets/linkvault_animated_ambient.dart';
import 'app_motion.dart';

export '../widgets/linkvault_animated_ambient.dart'
    show AmbientAwareFabGlow, AmbientMotionScope;

/// Ambient edge color — orbs and vignettes behind content, not on cards.
abstract final class LinkvaultGradients {
  /// Global scale for edge glow (0–1). Soft and serene, but clearly alive.
  static const double ambientIntensity = 0.82;

  static bool enabled(BuildContext context) => motionEnabled(context);

  static Widget ambientLayer(
    BuildContext context, {
    double intensity = ambientIntensity,
  }) {
    return IgnorePointer(
      child: LinkvaultAnimatedAmbient(intensity: intensity),
    );
  }
}
