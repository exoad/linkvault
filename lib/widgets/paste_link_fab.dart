import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../theme/app_motion.dart';
import '../theme/linkvault_design.dart';

class PasteLinkFab extends StatelessWidget {
  const PasteLinkFab({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final motion = motionEnabled(context);

    final fab = FloatingActionButton.extended(
      onPressed: onPressed,
      icon: PhosphorIcon(PhosphorIcons.link, size: 22),
      label: const Text(
        'Paste link',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    );

    Widget child = fab;
    if (motion) {
      child = fab
          .animate()
          .fadeIn(duration: AppMotion.normal, curve: AppMotion.standard)
          .scale(
            begin: const Offset(0.9, 0.9),
            end: const Offset(1, 1),
            duration: AppMotion.normal,
            curve: AppMotion.emphasized,
          );
    }

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        if (motion)
          Positioned(
            child: Container(
              width: 200,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: LinkvaultDesign.radiusControl,
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.35),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        child,
      ],
    );
  }
}
