import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_motion.dart';

Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    showDragHandle: true,
    builder: (context) {
      final sheet = builder(context);
      if (!motionEnabled(context)) return sheet;
      return sheet
          .animate()
          .fadeIn(duration: AppMotion.normal, curve: AppMotion.standard)
          .slideY(
            begin: 0.05,
            end: 0,
            duration: AppMotion.normal,
            curve: AppMotion.decelerate,
          );
    },
  );
}

Future<T?> showAnimatedDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showDialog<T>(
    context: context,
    builder: (context) {
      final dialog = builder(context);
      if (!motionEnabled(context)) return dialog;
      return dialog
          .animate()
          .fadeIn(duration: AppMotion.fast, curve: AppMotion.standard)
          .scale(
            begin: const Offset(0.96, 0.96),
            end: const Offset(1, 1),
            duration: AppMotion.normal,
            curve: AppMotion.emphasized,
          );
    },
  );
}
