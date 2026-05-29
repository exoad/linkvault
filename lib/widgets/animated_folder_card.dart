import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

class AnimatedFolderCard extends StatelessWidget {
  const AnimatedFolderCard({
    super.key,
    required this.isRemoving,
    required this.child,
  });

  final bool isRemoving;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: AppMotion.normal,
      curve: AppMotion.standard,
      alignment: Alignment.topCenter,
      child: AnimatedOpacity(
        duration: AppMotion.normal,
        curve: AppMotion.standard,
        opacity: isRemoving ? 0 : 1,
        child: AnimatedScale(
          scale: isRemoving ? 0.96 : 1,
          duration: AppMotion.normal,
          curve: AppMotion.standard,
          child: isRemoving
              ? const SizedBox(width: double.infinity, height: 0)
              : child,
        ),
      ),
    );
  }
}
