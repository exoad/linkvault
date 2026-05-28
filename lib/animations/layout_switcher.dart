import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// Cross-fades between list and grid bookmark layouts.
class LayoutSwitcher extends StatelessWidget {
  const LayoutSwitcher({
    super.key,
    required this.layoutKey,
    required this.child,
  });

  final Object layoutKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.normal,
      switchInCurve: AppMotion.emphasized,
      switchOutCurve: AppMotion.standard,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1).animate(
              CurvedAnimation(parent: animation, curve: AppMotion.emphasized),
            ),
            child: child,
          ),
        );
      },
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.topCenter,
          children: [
            ...previousChildren,
            ?currentChild,
          ],
        );
      },
      child: KeyedSubtree(
        key: ValueKey(layoutKey),
        child: child,
      ),
    );
  }
}
