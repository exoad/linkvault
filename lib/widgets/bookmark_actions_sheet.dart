import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../animations/animated_sheet.dart';
import '../theme/app_motion.dart';

typedef BookmarkActionCallback = void Function(BookmarkAction action);

enum BookmarkAction { open, copy, edit }

Future<BookmarkAction?> showBookmarkActionsSheet(BuildContext context) {
  return showAppBottomSheet<BookmarkAction>(
    context: context,
    builder: (context) {
      final tiles = [
        _ActionTile(
          index: 0,
          icon: PhosphorIcons.globe,
          label: 'Open',
          onTap: () => Navigator.pop(context, BookmarkAction.open),
        ),
        _ActionTile(
          index: 1,
          icon: PhosphorIcons.copy,
          label: 'Copy',
          onTap: () => Navigator.pop(context, BookmarkAction.copy),
        ),
        _ActionTile(
          index: 2,
          icon: PhosphorIcons.pencilSimple,
          label: 'Edit',
          onTap: () => Navigator.pop(context, BookmarkAction.edit),
        ),
      ];

      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: tiles,
        ),
      );
    },
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.index,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final int index;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tile = ListTile(
      leading: PhosphorIcon(icon),
      title: Text(label),
      onTap: onTap,
    );

    if (!motionEnabled(context)) return tile;

    return tile
        .animate()
        .fadeIn(
          duration: AppMotion.normal,
          delay: Duration(milliseconds: 30 * index),
        )
        .slideX(
          begin: 0.04,
          end: 0,
          duration: AppMotion.normal,
          curve: AppMotion.decelerate,
          delay: Duration(milliseconds: 30 * index),
        );
  }
}
