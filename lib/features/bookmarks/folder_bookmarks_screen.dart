import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../animations/animated_bookmark_list.dart';
import '../../animations/list_entrance.dart';
import '../../app_scope.dart';
import '../../models/bookmark.dart';
import '../../models/folder.dart';
import '../../models/layout_mode.dart';
import '../../services/layout_preferences.dart';
import '../../widgets/bookmark_card.dart';
import '../../theme/linkvault_design.dart';
import '../../widgets/linkvault_surface.dart';
import '../../widgets/phosphor_app_icon.dart';
import '../../widgets/layout_mode_toggle.dart';
import '../../widgets/linkvault_ambient_background.dart' show LinkvaultAmbientScaffold;
import '../../widgets/paste_link_fab.dart';
import '../../theme/linkvault_typography.dart';
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

  Future<void> _setLayoutMode(LayoutMode mode) async {
    if (mode == _layoutMode) return;
    await _layoutPrefs.setLayoutMode(mode);
    if (mounted) setState(() => _layoutMode = mode);
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

    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final linkLabel = widget.folder.bookmarkCount == 1
        ? '1 link'
        : '${widget.folder.bookmarkCount} links';

    return LinkvaultAmbientScaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
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
                  size: 24,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.folder.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          LayoutModeToggle(mode: _layoutMode, onChanged: _setLayoutMode),
        ],
      ),
      body: StreamBuilder<List<BookmarkModel>>(
        stream: repo.watchBookmarks(widget.folder.id),
        builder: (context, snapshot) {
          final bookmarks = snapshot.data ?? [];

          if (bookmarks.isEmpty) {
            final scheme = Theme.of(context).colorScheme;
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: StaggeredEmptyState(
                  children: [
                    LinkvaultSurface(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 32,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: scheme.surfaceContainerHighest,
                            child: PhosphorIcon(
                              PhosphorIcons.linkBreak,
                              size: 36,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: LinkvaultDesign.spaceXl),
                          Text(
                            'No links yet',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: LinkvaultDesign.spaceSm),
                          Text(
                            'Paste a link to save it in your hub.',
                            textAlign: TextAlign.center,
                            style: LinkvaultTypography.hubSubtitle(scheme),
                          ),
                          const SizedBox(height: LinkvaultDesign.spaceMd),
                          Text(
                            linkLabel,
                            style: LinkvaultTypography.meta(scheme),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
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

          final contentPadding = EdgeInsets.fromLTRB(
            16,
            MediaQuery.paddingOf(context).top + kToolbarHeight + 8,
            16,
            88 + bottomInset,
          );

          if (_layoutMode == LayoutMode.list) {
            return AnimatedBookmarkList(
              key: const ValueKey('bookmark-list'),
              padding: contentPadding,
              bookmarks: bookmarks,
              itemBuilder: (context, bookmark, animation) =>
                  _bookmarkCard(context, bookmark),
            );
          }

          return MasonryGridView.count(
            key: const ValueKey('bookmark-grid'),
            padding: contentPadding,
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            itemCount: bookmarks.length,
            itemBuilder: (context, index) {
              final bookmark = bookmarks[index];
              return _bookmarkCard(context, bookmark);
            },
          );
        },
      ),
      floatingActionButton: PasteLinkFab(
        onPressed: () => showAddLinkSheet(
          context,
          initialFolderId: widget.folder.id,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
