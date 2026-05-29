import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// M3-style shared-axis horizontal transition for folder → bookmarks.
class AppPageRoute<T> extends PageRouteBuilder<T> {
  AppPageRoute({required this.child})
      : super(
          opaque: true,
          pageBuilder: (context, animation, secondaryAnimation) {
            final surface = Theme.of(context).colorScheme.surface;
            return ColoredBox(color: surface, child: child);
          },
          transitionDuration: AppMotion.fast,
          reverseTransitionDuration: AppMotion.fast,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: AppMotion.standard,
              ),
              child: child,
            );
          },
        );

  final Widget child;
}
