import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/linkvault_accent.dart';
import '../theme/linkvault_design.dart';
import 'linkvault_animated_ambient.dart';

/// Flat container with a faint living tint drawn from the ambient glow.
///
/// No gradient fill or border — just a calm surface that breathes with the
/// same palette as the edges, so cards feel part of the serene whole.
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

  /// Whether to apply the subtle ambient tint (off for plain surfaces).
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = borderRadius ?? LinkvaultDesign.radiusCard;
    final base = color ?? scheme.surfaceContainerLow;

    final inner =
        padding != null ? Padding(padding: padding!, child: child) : child;

    final accent = tinted ? Theme.of(context).extension<LinkvaultAccent>() : null;
    final phase = tinted ? AmbientMotionScope.maybeOf(context) : null;

    Widget content;
    if (accent != null && phase != null) {
      content = _AmbientTintedBox(
        base: base,
        accent: accent,
        phase: phase,
        radius: radius,
        child: inner,
      );
    } else if (accent != null) {
      content = DecoratedBox(
        decoration: BoxDecoration(
          color: _tint(base, accent.cycleColor(0), 0.06),
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
      content = Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          onHighlightChanged: onHighlightChanged,
          borderRadius: radius,
          child: content,
        ),
      );
    }

    return content;
  }
}

/// Nudges [base] toward [tint] by [amount] while preserving the base alpha.
Color _tint(Color base, Color tint, double amount) {
  return Color.from(
    alpha: base.a,
    red: base.r + (tint.r - base.r) * amount,
    green: base.g + (tint.g - base.g) * amount,
    blue: base.b + (tint.b - base.b) * amount,
  );
}

/// Rebuilds only the surface fill each frame; [child] stays static.
class _AmbientTintedBox extends StatelessWidget {
  const _AmbientTintedBox({
    required this.base,
    required this.accent,
    required this.phase,
    required this.radius,
    required this.child,
  });

  final Color base;
  final LinkvaultAccent accent;
  final Animation<double> phase;
  final BorderRadius radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: phase,
      child: child,
      builder: (context, child) {
        // Containers drift slower than the edges for a calmer feel.
        final cycle = accent.cycleColor(phase.value * 0.5);
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
