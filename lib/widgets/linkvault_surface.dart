import 'package:flutter/material.dart';

import '../theme/linkvault_design.dart';

/// Flat bordered container — no Card elevation or drop shadows.
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
  });

  final Widget child;
  final Color? color;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final ValueChanged<bool>? onHighlightChanged;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = borderRadius ?? LinkvaultDesign.radiusCard;

    Widget content = DecoratedBox(
      decoration: LinkvaultDesign.surfaceDecoration(
        scheme,
        color: color,
        borderRadius: radius,
      ),
      child: padding != null ? Padding(padding: padding!, child: child) : child,
    );

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
