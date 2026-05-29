import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_motion.dart';
export 'interaction_motion.dart';

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
              ).scale(
                begin: const Offset(0.96, 0.96),
                end: const Offset(1, 1),
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
