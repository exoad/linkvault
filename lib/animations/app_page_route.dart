import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// M3-style shared-axis horizontal transition for folder → bookmarks.
class AppPageRoute<T> extends PageRouteBuilder<T> {
  AppPageRoute({required this.child})
      : super(
          opaque: false,
          barrierColor: Colors.transparent,
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: AppMotion.slow,
          reverseTransitionDuration: AppMotion.normal,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: AppMotion.emphasized,
              reverseCurve: AppMotion.emphasized,
            );
            final offsetTween = Tween<Offset>(
              begin: const Offset(0.08, 0),
              end: Offset.zero,
            );
            final secondaryOffset = Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(-0.04, 0),
            );
            return SlideTransition(
              position: offsetTween.animate(curved),
              child: SlideTransition(
                position: secondaryOffset.animate(
                  CurvedAnimation(
                    parent: secondaryAnimation,
                    curve: AppMotion.standard,
                  ),
                ),
                child: child,
              ),
            );
          },
        );

  final Widget child;
}
