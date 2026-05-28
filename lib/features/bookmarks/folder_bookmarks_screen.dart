import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../animations/animated_bookmark_list.dart';
import '../../animations/layout_switcher.dart';
import '../../animations/list_entrance.dart';
import '../../app_scope.dart';
import '../../models/bookmark.dart';
import '../../models/folder.dart';
import '../../models/layout_mode.dart';
import '../../services/layout_preferences.dart';
import '../../widgets/bookmark_card.dart';
import '../../widgets/phosphor_app_icon.dart';
import '../../widgets/layout_mode_toggle.dart';
import '../../widgets/paste_link_fab.dart';
import '../add_link/add_link_sheet.dart';
import 'bookmark_actions.dart';

class FolderBookmarksScreen extends StatefulWidget {
  const FolderBookmarksScreen({super.key, required this.folder});

  final FolderModel folder;

  @override
  State<FolderBookmarksScreen> createState() => _FolderBookmarksScreenState();
}

class _FolderBookmarksScreenState extends State<FolderBookmarksScreen> {
  final _layoutPrefs = LayoutPreferences();
  LayoutMode _layoutMode = LayoutMode.list;

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

  Future<void> _fetchTitle(String bookmarkId) async {
    final repo = AppScope.of(context);
    final ok = await repo.tryFetchMetadataForBookmark(bookmarkId);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No connection')),
      );
    }
  }

  Widget _bookmarkCard(BuildContext context, BookmarkModel bookmark) {
    return BookmarkCard(
      bookmark: bookmark,
      onTap: () => handleBookmarkTap(context, bookmark),
      onFetchTitle:
          bookmark.needsFetch ? () => _fetchTitle(bookmark.id) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Hero(
          tag: 'folder-${widget.folder.id}',
          child: Material(
            type: MaterialType.transparency,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PhosphorAppIcon(
                  widget.folder.iconName,
                  color: widget.folder.color,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Flexible(child: Text(widget.folder.name)),
              ],
            ),
          ),
        ),
        actions: [
          LayoutModeToggle(mode: _layoutMode, onChanged: (_) => _toggleLayout()),
        ],
      ),
      body: StreamBuilder<List<BookmarkModel>>(
        stream: repo.watchBookmarks(widget.folder.id),
        builder: (context, snapshot) {
          final bookmarks = snapshot.data ?? [];

          if (bookmarks.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: StaggeredEmptyState(
                  children: [
                    PhosphorIcon(PhosphorIcons.linkBreak, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'No links yet',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text('Paste a link to save it in this folder.'),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => showAddLinkSheet(
                        context,
                        initialFolderId: widget.folder.id,
                      ),
                      icon: PhosphorIcon(PhosphorIcons.link),
                      label: const Text('Paste link'),
                    ),
                  ],
                ),
              ),
            );
          }

          return LayoutSwitcher(
            layoutKey: _layoutMode,
            child: _layoutMode == LayoutMode.list
                ? AnimatedBookmarkList(
                    bookmarks: bookmarks,
                    itemBuilder: (context, bookmark, animation) =>
                        _bookmarkCard(context, bookmark),
                  )
                : MasonryGridView.count(
                    padding: const EdgeInsets.all(12),
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    itemCount: bookmarks.length,
                    itemBuilder: (context, index) {
                      final bookmark = bookmarks[index];
                      return _bookmarkCard(context, bookmark)
                          .listEntrance(context, index: index);
                    },
                  ),
          );
        },
      ),
      floatingActionButton: PasteLinkFab(
        onPressed: () => showAddLinkSheet(
          context,
          initialFolderId: widget.folder.id,
        ),
      ),
    );
  }
}
