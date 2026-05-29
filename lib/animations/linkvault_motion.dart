import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_motion.dart';
import 'interaction_motion.dart';

export 'interaction_motion.dart';
export 'list_entrance.dart';

/// Linkvault motion primitives — respect [motionEnabled].
extension LinkvaultMotion on Widget {
  /// Chat status strip fade-in.
  Widget statusEntrance(BuildContext context) {
    if (!motionEnabled(context)) return this;
    return animate()
        .fadeIn(duration: AppMotion.fast, curve: AppMotion.standard)
        .slideY(
          begin: 0.08,
          end: 0,
          duration: AppMotion.fast,
          curve: AppMotion.decelerate,
        );
  }

  /// Chat message bubble entrance.
  Widget messageEntrance(BuildContext context, {required int index}) {
    if (!motionEnabled(context)) return this;
    final delay = AppMotion.staggerDelay(index.clamp(0, 12));
    return animate()
        .fadeIn(
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          delay: delay,
        )
        .slideY(
          begin: 0.03,
          end: 0,
          duration: AppMotion.fast,
          curve: AppMotion.decelerate,
          delay: delay,
        );
  }

  /// Bottom sheet row stagger.
  Widget sheetRowEntrance(BuildContext context, {required int index}) {
    return listEntrance(context, index: index);
  }

  /// Icon chips and small badges.
  Widget chipEntrance(BuildContext context) {
    if (!motionEnabled(context)) return this;
    return animate()
        .fadeIn(duration: AppMotion.micro, curve: AppMotion.standard)
        .scale(
          begin: const Offset(0.92, 0.92),
          end: const Offset(1, 1),
          duration: AppMotion.micro,
          curve: AppMotion.spring,
        );
  }

  /// Toggles and segmented controls.
  Widget toggleEntrance(BuildContext context) {
    if (!motionEnabled(context)) return this;
    return animate()
        .fadeIn(duration: AppMotion.normal, curve: AppMotion.standard)
        .slideX(
          begin: 0.04,
          end: 0,
          duration: AppMotion.normal,
          curve: AppMotion.decelerate,
        );
  }
}

/// Wraps [child] with [AlivePressable] when [onTap] is set.
Widget linkvaultPressable({
  required Widget child,
  VoidCallback? onTap,
  VoidCallback? onLongPress,
  BorderRadius? borderRadius,
  bool enabled = true,
}) {
  if (onTap == null && onLongPress == null) return child;
  return AlivePressable(
    onTap: onTap,
    onLongPress: onLongPress,
    borderRadius: borderRadius,
    enabled: enabled,
    child: child,
  );
}
