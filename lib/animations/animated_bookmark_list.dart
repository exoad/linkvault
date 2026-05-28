import 'package:flutter/material.dart';

import '../models/bookmark.dart';
import '../theme/app_motion.dart';

/// Syncs a bookmark list from a stream to [AnimatedList] insert/remove transitions.
class AnimatedBookmarkList extends StatefulWidget {
  const AnimatedBookmarkList({
    super.key,
    required this.bookmarks,
    required this.itemBuilder,
    this.padding = const EdgeInsets.all(12),
  });

  final List<BookmarkModel> bookmarks;
  final Widget Function(
    BuildContext context,
    BookmarkModel bookmark,
    Animation<double> animation,
  ) itemBuilder;
  final EdgeInsets padding;

  @override
  State<AnimatedBookmarkList> createState() => _AnimatedBookmarkListState();
}

class _AnimatedBookmarkListState extends State<AnimatedBookmarkList> {
  final _listKey = GlobalKey<AnimatedListState>();
  final List<BookmarkModel> _items = [];

  @override
  void initState() {
    super.initState();
    _items.addAll(widget.bookmarks);
  }

  @override
  void didUpdateWidget(AnimatedBookmarkList oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync(widget.bookmarks);
  }

  void _sync(List<BookmarkModel> next) {
    if (!mounted) return;

    for (var i = _items.length - 1; i >= 0; i--) {
      if (!next.any((b) => b.id == _items[i].id)) {
        final removed = _items.removeAt(i);
        _listKey.currentState?.removeItem(
          i,
          (context, animation) => _buildItem(context, removed, animation),
          duration: AppMotion.normal,
        );
      }
    }

    for (var i = 0; i < next.length; i++) {
      if (i < _items.length && _items[i].id == next[i].id) {
        _items[i] = next[i];
        continue;
      }
      final insert = next[i];
      if (_items.any((b) => b.id == insert.id)) continue;
      _items.insert(i, insert);
      _listKey.currentState?.insertItem(i, duration: AppMotion.normal);
    }

    setState(() {});
  }

  Widget _buildItem(
    BuildContext context,
    BookmarkModel bookmark,
    Animation<double> animation,
  ) {
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: animation.drive(
            Tween<Offset>(
              begin: const Offset(0, 0.15),
              end: Offset.zero,
            ).chain(CurveTween(curve: AppMotion.decelerate)),
          ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: widget.itemBuilder(context, bookmark, animation),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      key: _listKey,
      clipBehavior: Clip.none,
      padding: widget.padding,
      initialItemCount: _items.length,
      itemBuilder: (context, index, animation) {
        if (index >= _items.length) return const SizedBox.shrink();
        return _buildItem(context, _items[index], animation);
      },
    );
  }
}
