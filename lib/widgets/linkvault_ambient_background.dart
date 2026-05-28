import 'package:flutter/material.dart';

import '../theme/linkvault_gradients.dart';

/// Scaffold body with solid surface base and optional ambient gradient glow.
class LinkvaultAmbientBackground extends StatelessWidget {
  const LinkvaultAmbientBackground({
    super.key,
    required this.child,
    this.intensity = 1.0,
  });

  final Widget child;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: scheme.surface),
        LinkvaultGradients.ambientLayer(context, intensity: intensity),
        child,
      ],
    );
  }
}
