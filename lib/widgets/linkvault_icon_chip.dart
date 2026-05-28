import 'package:flutter/material.dart';

/// Shared icon container — soft rounded square with a faint tint of [color].
///
/// One consistent treatment for folders, hub apps, notes, and empty states so
/// the UI feels like a single system rather than mismatched avatars.
class LinkvaultIconChip extends StatelessWidget {
  const LinkvaultIconChip({
    super.key,
    required this.color,
    required this.child,
    this.dimension = 52,
    this.fill = 0.16,
  });

  final Color color;
  final Widget child;
  final double dimension;
  final double fill;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: dimension,
      height: dimension,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: fill),
        borderRadius: BorderRadius.circular(dimension * 0.32),
      ),
      child: child,
    );
  }
}
