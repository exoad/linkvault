import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../theme/app_motion.dart';

class PasteLinkFab extends StatelessWidget {
  const PasteLinkFab({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final fab = FloatingActionButton.extended(
      onPressed: onPressed,
      icon: PhosphorIcon(PhosphorIcons.link),
      label: const Text('Paste link'),
    );

    if (!motionEnabled(context)) return fab;

    return fab
        .animate()
        .fadeIn(duration: AppMotion.normal, curve: AppMotion.standard)
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1, 1),
          duration: AppMotion.normal,
          curve: AppMotion.emphasized,
        );
  }
}
