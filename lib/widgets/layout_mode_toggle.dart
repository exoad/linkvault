import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../models/layout_mode.dart';

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
    return IconButton(
      tooltip: mode == LayoutMode.list ? 'Grid view' : 'List view',
      icon: PhosphorIcon(
        mode == LayoutMode.list
            ? PhosphorIcons.squaresFour
            : PhosphorIcons.list,
      ),
      onPressed: () {
        onChanged(mode == LayoutMode.list ? LayoutMode.grid : LayoutMode.list);
      },
    );
  }
}
