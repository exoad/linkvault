import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../animations/animated_sheet.dart';
import '../../animations/app_page_route.dart';
import '../../animations/layout_switcher.dart';
import '../../animations/list_entrance.dart';
import '../../app_scope.dart';
import '../../models/folder.dart';
import '../../models/layout_mode.dart';
import '../../services/layout_preferences.dart';
import '../../theme/theme_controller.dart';
import '../../widgets/animated_folder_card.dart';
import '../../widgets/folder_grid_tile.dart';
import '../../widgets/folder_list_tile.dart';
import '../../widgets/layout_mode_toggle.dart';
import '../../widgets/paste_link_fab.dart';
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

  Future<void> _setLayoutMode(LayoutMode mode) async {
    if (mode == _layoutMode) return;
    await _layoutPrefs.setLayoutMode(mode);
    if (mounted) setState(() => _layoutMode = mode);
  }

  Future<void> _openSettings() async {
    await Navigator.push<void>(
      context,
      AppPageRoute(
        child: SettingsScreen(themeController: widget.themeController),
      ),
    );
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
    await Future<void>.delayed(const Duration(milliseconds: 250));
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

  int _totalLinks(List<FolderModel> folders) {
    return folders.fold<int>(0, (sum, f) => sum + f.bookmarkCount);
  }

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: const Text('Linkvault'),
        actions: [
          LayoutModeToggle(mode: _layoutMode, onChanged: _setLayoutMode),
          IconButton(
            tooltip: 'Settings',
            icon: PhosphorIcon(PhosphorIcons.gear),
            onPressed: _openSettings,
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

          final linkCount = _totalLinks(folders);
          final linkLabel = linkCount == 1 ? '1 link saved' : '$linkCount links saved';

          final header = Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your folders',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  linkLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          );

          Widget folderTile(FolderModel folder, int index) {
            final locked =
                folder.requiresUnlock && !repo.canAccessFolder(folder);
            final isRemoving = _removingFolderIds.contains(folder.id);
            final onMenu =
                folder.isSystem ? null : () => _showFolderMenu(folder);

            final tile = _layoutMode == LayoutMode.list
                ? FolderListTile(
                    folder: folder,
                    locked: locked,
                    onTap: () => _openFolder(folder),
                    onMenu: onMenu,
                  )
                : FolderGridTile(
                    folder: folder,
                    locked: locked,
                    onTap: () => _openFolder(folder),
                    onMenu: onMenu,
                  );

            return AnimatedFolderCard(
              isRemoving: isRemoving,
              child: tile.listEntrance(context, index: index),
            );
          }

          return LayoutSwitcher(
            layoutKey: _layoutMode,
            child: _layoutMode == LayoutMode.list
                ? ListView.separated(
                    clipBehavior: Clip.none,
                    padding:
                        EdgeInsets.fromLTRB(16, 4, 16, 88 + bottomInset),
                    itemCount: folders.length + 1,
                    separatorBuilder: (_, index) => index == 0
                        ? const SizedBox(height: 12)
                        : const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      if (index == 0) return header;
                      return folderTile(folders[index - 1], index - 1);
                    },
                  )
                : CustomScrollView(
                    clipBehavior: Clip.none,
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          4,
                          16,
                          88 + bottomInset,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            header,
                            const SizedBox(height: 12),
                          ]),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1.05,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) =>
                                folderTile(folders[index], index),
                            childCount: folders.length,
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.only(bottom: 88 + bottomInset),
                      ),
                    ],
                  ),
          );
        },
      ),
      floatingActionButton: PasteLinkFab(
        onPressed: () => showAddLinkSheet(context),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
