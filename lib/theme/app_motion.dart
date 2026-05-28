import 'package:flutter/material.dart';

/// Shared motion tokens for Linkvault.
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);

  static const Duration staggerStep = Duration(milliseconds: 40);
  static const Duration dialogStaggerStep = Duration(milliseconds: 80);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeInOutCubic;
  static const Curve decelerate = Curves.decelerate;

  static Duration staggerDelay(int index) =>
      Duration(milliseconds: staggerStep.inMilliseconds * index);
}

bool motionEnabled(BuildContext context) {
  return !MediaQuery.disableAnimationsOf(context);
}
