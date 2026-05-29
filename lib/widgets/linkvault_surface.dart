import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../animations/interaction_motion.dart';
import '../theme/ambient_lava_palette.dart';
import '../theme/linkvault_design.dart';
import 'linkvault_animated_ambient.dart';

/// Flat container with a faint living tint and soft press feedback.
class LinkvaultSurface extends StatelessWidget {
  const LinkvaultSurface({
    super.key,
    required this.child,
    this.color,
    this.borderRadius,
    this.onTap,
    this.onLongPress,
    this.onHighlightChanged,
    this.padding,
    this.tinted = true,
  });

  final Widget child;
  final Color? color;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final ValueChanged<bool>? onHighlightChanged;
  final EdgeInsetsGeometry? padding;
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = borderRadius ?? LinkvaultDesign.radiusCard;
    final base = color ?? scheme.surfaceContainerLow;

    final inner =
        padding != null ? Padding(padding: padding!, child: child) : child;

    final phase = tinted ? AmbientMotionScope.maybeOf(context) : null;

    Widget content;
    if (phase != null) {
      content = _AmbientTintedBox(
        base: base,
        phase: phase,
        radius: radius,
        child: inner,
      );
    } else if (tinted) {
      content = DecoratedBox(
        decoration: BoxDecoration(
          color: _tint(base, AmbientLavaPalette.colorAt(0), 0.06),
          borderRadius: radius,
        ),
        child: inner,
      );
    } else {
      content = DecoratedBox(
        decoration: BoxDecoration(color: base, borderRadius: radius),
        child: inner,
      );
    }

    if (onTap != null || onLongPress != null) {
      content = AlivePressable(
        onTap: onTap,
        onLongPress: onLongPress,
        onHighlightChanged: onHighlightChanged,
        borderRadius: radius,
        child: content,
      );
    }

    return content;
  }
}

Color _tint(Color base, Color tint, double amount) {
  return Color.from(
    alpha: base.a,
    red: base.r + (tint.r - base.r) * amount,
    green: base.g + (tint.g - base.g) * amount,
    blue: base.b + (tint.b - base.b) * amount,
  );
}

class _AmbientTintedBox extends StatelessWidget {
  const _AmbientTintedBox({
    required this.base,
    required this.phase,
    required this.radius,
    required this.child,
  });

  final Color base;
  final Animation<double> phase;
  final BorderRadius radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: phase,
      child: child,
      builder: (context, child) {
        final cycle = AmbientLavaPalette.colorAt(phase.value * 0.5);
        final breathe = 0.5 + 0.5 * math.sin(phase.value * math.pi * 2);
        final amount = 0.05 + 0.03 * breathe;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: _tint(base, cycle, amount),
            borderRadius: radius,
          ),
          child: child,
        );
      },
    );
  }
}
