import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../animations/interaction_motion.dart';
import '../models/layout_mode.dart';
import '../theme/app_motion.dart';

class LayoutModeToggle extends StatelessWidget {
  const LayoutModeToggle({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  final LayoutMode mode;
  final ValueChanged<LayoutMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final isList = mode == LayoutMode.list;
    return AliveIconButton(
      tooltip: isList ? 'Grid view' : 'List view',
      onPressed: () {
        onChanged(isList ? LayoutMode.grid : LayoutMode.list);
      },
      icon: AnimatedSwitcher(
        duration: AppMotion.normal,
        switchInCurve: AppMotion.spring,
        switchOutCurve: AppMotion.standard,
        transitionBuilder: (child, animation) {
          return ScaleTransition(
            scale: animation,
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: PhosphorIcon(
          key: ValueKey(isList),
          isList ? PhosphorIcons.squaresFour : PhosphorIcons.list,
        ),
      ),
    );
  }
}
