import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../models/folder.dart';
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

    return Card(
      child: InkWell(
        onTap: onTap,
        onLongPress: onMenu,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: folder.color.withValues(alpha: 0.18),
              child: PhosphorAppIcon(
                folder.iconName,
                color: folder.color,
                size: 26,
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
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
            subtitle: Text(subtitleText),
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
        ),
      ),
    );
  }
}
