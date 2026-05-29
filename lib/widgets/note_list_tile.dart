import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../hub/hub_module.dart';
import '../models/note.dart';
import '../theme/hub_app_colors.dart' show HubAppColors, HubAppPalette;
import 'linkvault_animated_ambient.dart';
import 'linkvault_icon_chip.dart';
import 'linkvault_surface.dart';

class NoteListTile extends StatelessWidget {
  const NoteListTile({
    super.key,
    required this.note,
    required this.app,
    required this.onTap,
    required this.onDelete,
  });

  final NoteModel note;
  final HubAppDefinition app;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final phase = AmbientMotionScope.maybeOf(context);

    final palette = phase != null
        ? HubAppColors.palette(app, phase.value + note.id.hashCode * 0.001)
        : HubAppPalette(
            primary: app.seedPrimary,
            secondary: app.seedSecondary,
            tertiary: app.seedSecondary,
            glow: app.seedPrimary.withValues(alpha: 0.2),
          );

    final updated = _formatWhen(note.updatedAt);

    return LinkvaultSurface(
      onTap: onTap,
      onLongPress: onDelete,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinkvaultIconChip(
            color: palette.primary,
            dimension: 48,
            child: PhosphorIcon(
              PhosphorIcons.note,
              color: palette.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  note.preview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  updated,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: PhosphorIcon(
              PhosphorIcons.trash,
              size: 20,
              color: scheme.onSurfaceVariant,
            ),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  String _formatWhen(DateTime time) {
    final now = DateTime.now();
    final local = time.toLocal();
    if (now.difference(local).inDays == 0) {
      final h = local.hour.toString().padLeft(2, '0');
      final m = local.minute.toString().padLeft(2, '0');
      return 'Today · $h:$m';
    }
    if (now.difference(local).inDays == 1) {
      return 'Yesterday';
    }
    return '${local.month}/${local.day}/${local.year}';
  }
}
