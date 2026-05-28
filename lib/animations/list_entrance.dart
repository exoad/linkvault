import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_motion.dart';

extension ListEntrance on Widget {
  /// Staggered fade + slide for list/grid children on first appearance.
  Widget listEntrance(
    BuildContext context, {
    required int index,
    Duration? delay,
  }) {
    if (!motionEnabled(context)) return this;
    final stagger = delay ?? AppMotion.staggerDelay(index);
    return animate()
        .fadeIn(
          duration: AppMotion.normal,
          curve: AppMotion.standard,
          delay: stagger,
        )
        .slideY(
          begin: 0.08,
          end: 0,
          duration: AppMotion.normal,
          curve: AppMotion.decelerate,
          delay: stagger,
        );
  }
}

/// Staggered column children for empty states (icon → title → CTA).
class StaggeredEmptyState extends StatelessWidget {
  const StaggeredEmptyState({
    super.key,
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (!motionEnabled(context)) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: children,
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < children.length; i++)
          children[i].animate().fadeIn(
                duration: AppMotion.normal,
                delay: Duration(
                  milliseconds:
                      AppMotion.dialogStaggerStep.inMilliseconds * i,
                ),
              ).slideY(
                begin: 0.06,
                end: 0,
                duration: AppMotion.normal,
                curve: AppMotion.decelerate,
                delay: Duration(
                  milliseconds:
                      AppMotion.dialogStaggerStep.inMilliseconds * i,
                ),
              ),
      ],
    );
  }
}
