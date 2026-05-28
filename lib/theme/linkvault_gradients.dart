import 'package:flutter/material.dart';

import '../widgets/linkvault_animated_ambient.dart';
import 'app_motion.dart';

export '../widgets/linkvault_animated_ambient.dart'
    show AmbientAwareFabGlow, AmbientMotionScope;

/// Ambient edge color — orbs and vignettes behind content, not on cards.
abstract final class LinkvaultGradients {
  static bool enabled(BuildContext context) => motionEnabled(context);

  static Widget ambientLayer(
    BuildContext context, {
    double intensity = 1.0,
  }) {
    return IgnorePointer(
      child: LinkvaultAnimatedAmbient(intensity: intensity),
    );
  }
}
