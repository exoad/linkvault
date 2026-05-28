import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../animations/animated_sheet.dart';
import '../../animations/app_page_route.dart';
import '../../animations/list_entrance.dart';
import '../../app_scope.dart';
import '../../hub/modules/links_hub_module.dart';
import '../../models/folder.dart';
import '../../models/layout_mode.dart';
import '../../services/layout_preferences.dart';
import '../../theme/hub_app_colors.dart';
import '../../theme/linkvault_accent.dart';
import '../../theme/linkvault_design.dart';
import '../../widgets/animated_folder_card.dart';
import '../../widgets/folder_grid_tile.dart';
import '../../widgets/folder_list_tile.dart';
import '../../widgets/layout_mode_toggle.dart';
import '../../widgets/linkvault_animated_ambient.dart';
import '../../widgets/linkvault_ambient_background.dart';
import '../../widgets/paste_link_fab.dart';
import '../add_link/add_link_sheet.dart';
import '../bookmarks/folder_bookmarks_screen.dart';
import '../folders/folder_editor_sheet.dart';

/// Links hub app — folders and saved URLs.
class LinksAppScreen extends StatefulWidget {
  const LinksAppScreen({super.key});

  @override
  State<LinksAppScreen> createState() => _LinksAppScreenState();
}

class _LinksAppScreenState extends State<LinksAppScreen> {
  static const _app = LinksHubModule.appDefinition;

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
    final accent = Theme.of(context).extension<LinkvaultAccent>();
    final phase = AmbientMotionScope.maybeOf(context);

    Widget appBarTitle(Color iconColor) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(PhosphorIcons.link, color: iconColor, size: 22),
            const SizedBox(width: 8),
            const Text('Links'),
          ],
        );

    final title = accent != null && phase != null
        ? AnimatedBuilder(
            animation: phase,
            builder: (context, _) => appBarTitle(
              HubAppColors.palette(accent, _app, phase.value).primary,
            ),
          )
        : appBarTitle(_app.seedPrimary);

    return LinkvaultAmbientScaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: const BackButton(),
        title: title,
        actions: [
          LayoutModeToggle(mode: _layoutMode, onChanged: _setLayoutMode),
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
          final linkLabel =
              linkCount == 1 ? '1 link' : '$linkCount links';

          final header = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Folders',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: LinkvaultDesign.spaceXs),
              Text(
                linkLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: LinkvaultDesign.spaceLg),
            ],
          );

          Widget folderTile(FolderModel folder) {
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
              child: tile,
            );
          }

          final topPad =
              MediaQuery.paddingOf(context).top + kToolbarHeight + 8;

          return CustomScrollView(
            clipBehavior: Clip.none,
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, topPad, 16, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([header]),
                ),
              ),
              if (_layoutMode == LayoutMode.list)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: EdgeInsets.only(
                          bottom: index < folders.length - 1 ? 12 : 0,
                        ),
                        child: folderTile(folders[index]),
                      ),
                      childCount: folders.length,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.92,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => folderTile(folders[index]),
                      childCount: folders.length,
                    ),
                  ),
                ),
              SliverPadding(
                padding: EdgeInsets.only(bottom: 88 + bottomInset),
              ),
            ],
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
