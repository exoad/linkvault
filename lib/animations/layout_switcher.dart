import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// Swaps list/grid with a brief cross-fade (no full-screen slide flicker).
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
      duration: AppMotion.micro,
      switchInCurve: AppMotion.decelerate,
      switchOutCurve: AppMotion.standard,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.topCenter,
          children: [
            ...previousChildren,
            ?currentChild,
          ],
        );
      },
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: KeyedSubtree(
        key: ValueKey(layoutKey),
        child: child,
      ),
    );
  }
}
