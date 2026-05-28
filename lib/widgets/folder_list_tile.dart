import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../models/folder.dart';
import 'linkvault_surface.dart';
import 'phosphor_app_icon.dart';

class FolderListTile extends StatelessWidget {
  const FolderListTile({
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: folder.color.withValues(alpha: 0.2),
          child: PhosphorAppIcon(
            folder.iconName,
            color: folder.color,
            size: 30,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Hero(
                tag: 'folder-${folder.id}',
                child: Material(
                  type: MaterialType.transparency,
                  child: Text(
                    folder.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
            ),
            if (folder.requiresUnlock)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: PhosphorIcon(
                  locked ? PhosphorIcons.lock : PhosphorIcons.lockOpen,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        subtitle: Text(
          subtitleText,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: onMenu == null
            ? PhosphorIcon(
                PhosphorIcons.caretRight,
                color: scheme.onSurfaceVariant,
              )
            : IconButton(
                icon: PhosphorIcon(PhosphorIcons.dotsThreeVertical),
                onPressed: onMenu,
              ),
      ),
    );
  }
}
