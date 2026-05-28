import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../animations/animated_sheet.dart';
import '../../animations/app_page_route.dart';
import '../../animations/list_entrance.dart';
import '../../app_scope.dart';
import '../../models/folder.dart';
import '../../models/layout_mode.dart';
import '../../services/layout_preferences.dart';
import '../../theme/app_motion.dart';
import '../../theme/theme_controller.dart';
import '../../widgets/animated_folder_card.dart';
import '../../widgets/layout_mode_toggle.dart';
import '../../widgets/paste_link_fab.dart';
import '../../widgets/phosphor_app_icon.dart';
import '../add_link/add_link_sheet.dart';
import '../bookmarks/folder_bookmarks_screen.dart';
import '../settings/settings_screen.dart';
import 'folder_editor_sheet.dart';

class FoldersScreen extends StatefulWidget {
  const FoldersScreen({super.key, required this.themeController});

  final ThemeController themeController;

  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  final _layoutPrefs = LayoutPreferences();
  LayoutMode _layoutMode = LayoutMode.list;
  final Set<String> _removingFolderIds = {};

  @override
  void initState() {
    super.initState();
    _loadLayoutMode();
  }

  Future<void> _loadLayoutMode() async {
    final mode = await _layoutPrefs.getLayoutMode();
    if (mounted) setState(() => _layoutMode = mode);
  }

  Future<void> _toggleLayout() async {
    final next =
        _layoutMode == LayoutMode.list ? LayoutMode.grid : LayoutMode.list;
    await _layoutPrefs.setLayoutMode(next);
    if (mounted) setState(() => _layoutMode = next);
  }

  Future<void> _createFolder() async {
    final result = await showFolderEditorSheet(context);
    if (result == null || !mounted) return;
    try {
      await AppScope.of(context).createFolder(result.upsert);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not create folder: $e')),
        );
      }
    }
  }

  Future<void> _editFolder(FolderModel folder) async {
    final result = await showFolderEditorSheet(context, existing: folder);
    if (result == null || !result.isEdit || !mounted) return;
    try {
      await AppScope.of(context).updateFolder(folder.id, result.upsert);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update folder: $e')),
        );
      }
    }
  }

  Future<void> _deleteFolder(FolderModel folder) async {
    final confirmed = await showAnimatedDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${folder.name}"?'),
        content: Text(
          folder.bookmarkCount > 0
              ? '${folder.bookmarkCount} link(s) will move to Unfiled.'
              : 'This folder will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _removingFolderIds.add(folder.id));
    await Future<void>.delayed(AppMotion.normal);
    if (!mounted) return;

    try {
      await AppScope.of(context).deleteFolder(folder.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _removingFolderIds.remove(folder.id));
      }
    }
  }

  Future<void> _openFolder(FolderModel folder) async {
    final repo = AppScope.of(context);
    if (!repo.canAccessFolder(folder)) {
      final unlocked = await showUnlockFolderSheet(context, folder: folder);
      if (!unlocked || !mounted) return;
    }
    if (!mounted) return;
    await Navigator.push<void>(
      context,
      AppPageRoute(child: FolderBookmarksScreen(folder: folder)),
    );
    if (mounted) {
      repo.lockFolder(folder.id);
    }
  }

  void _showFolderMenu(FolderModel folder) {
    showAppBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: PhosphorIcon(PhosphorIcons.pencilSimple),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                _editFolder(folder);
              },
            ).listEntrance(context, index: 0),
            if (folder.requiresUnlock)
              ListTile(
                leading: PhosphorIcon(PhosphorIcons.lockOpen),
                title: const Text('Lock now'),
                onTap: () {
                  AppScope.of(context).lockFolder(folder.id);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Folder locked')),
                  );
                },
              ).listEntrance(context, index: 1),
            ListTile(
              leading: PhosphorIcon(
                PhosphorIcons.trash,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteFolder(folder);
              },
            ).listEntrance(context, index: 2),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Linkvault'),
        actions: [
          LayoutModeToggle(mode: _layoutMode, onChanged: (_) => _toggleLayout()),
          IconButton(
            tooltip: 'Appearance',
            icon: PhosphorIcon(PhosphorIcons.palette),
            onPressed: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => SettingsScreen(
                    themeController: widget.themeController,
                  ),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'New folder',
            icon: PhosphorIcon(PhosphorIcons.folderPlus),
            onPressed: _createFolder,
          ),
        ],
      ),
      body: StreamBuilder<List<FolderModel>>(
        stream: repo.watchFolders(),
        builder: (context, snapshot) {
          final folders = snapshot.data ?? [];
          if (folders.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: folders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final folder = folders[index];
              final subtitle = folder.bookmarkCount == 1
                  ? '1 link'
                  : '${folder.bookmarkCount} links';
              final isRemoving = _removingFolderIds.contains(folder.id);
              final locked = folder.requiresUnlock &&
                  !repo.canAccessFolder(folder);

              final card = Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: folder.color.withValues(alpha: 0.2),
                    child: PhosphorAppIcon(
                      folder.iconName,
                      color: folder.color,
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Hero(
                          tag: 'folder-${folder.id}',
                          child: Material(
                            type: MaterialType.transparency,
                            child: Text(folder.name),
                          ),
                        ),
                      ),
                      if (folder.requiresUnlock)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: PhosphorIcon(
                            locked
                                ? PhosphorIcons.lock
                                : PhosphorIcons.lockOpen,
                            size: 18,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    locked ? 'Locked · $subtitle' : subtitle,
                  ),
                  trailing: folder.isSystem
                      ? null
                      : IconButton(
                          icon: PhosphorIcon(PhosphorIcons.dotsThreeVertical),
                          onPressed: () => _showFolderMenu(folder),
                        ),
                  onTap: () => _openFolder(folder),
                  onLongPress:
                      folder.isSystem ? null : () => _showFolderMenu(folder),
                ),
              );

              return AnimatedFolderCard(
                isRemoving: isRemoving,
                child: card.listEntrance(context, index: index),
              );
            },
          );
        },
      ),
      floatingActionButton: PasteLinkFab(
        onPressed: () => showAddLinkSheet(context),
      ),
    );
  }
}
