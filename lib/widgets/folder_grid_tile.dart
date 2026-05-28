import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../models/folder.dart';
import '../theme/linkvault_design.dart';
import 'linkvault_icon_chip.dart';
import 'linkvault_surface.dart';
import 'phosphor_app_icon.dart';

/// Compact folder cell for grid layout on the home screen.
class FolderGridTile extends StatelessWidget {
  const FolderGridTile({
    super.key,
    required this.folder,
    required this.locked,
    required this.onTap,
    this.onMenu,
  });

  final FolderModel folder;
  final bool locked;
  final VoidCallback onTap;
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final subtitle = folder.bookmarkCount == 1
        ? '1 link'
        : '${folder.bookmarkCount} links';
    final subtitleText = locked ? 'Locked · $subtitle' : subtitle;

    return LinkvaultSurface(
      onTap: onTap,
      onLongPress: onMenu,
      padding: const EdgeInsets.all(LinkvaultDesign.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LinkvaultIconChip(
                color: folder.color,
                dimension: 48,
                child: PhosphorAppIcon(
                  folder.iconName,
                  color: folder.color,
                  size: 24,
                ),
              ),
              const Spacer(),
              if (folder.requiresUnlock)
                PhosphorIcon(
                  locked ? PhosphorIcons.lock : PhosphorIcons.lockOpen,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
              if (onMenu != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  icon: PhosphorIcon(PhosphorIcons.dotsThreeVertical),
                  onPressed: onMenu,
                ),
              ],
            ],
          ),
          const SizedBox(height: LinkvaultDesign.spaceMd),
          Hero(
            tag: 'folder-${folder.id}',
            child: Material(
              type: MaterialType.transparency,
              child: Text(
                folder.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
          const SizedBox(height: LinkvaultDesign.spaceXs),
          Text(
            subtitleText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
