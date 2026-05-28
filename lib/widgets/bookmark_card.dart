import 'package:flutter/material.dart';

import '../models/bookmark.dart';
import '../models/fetch_status.dart';
import '../theme/app_motion.dart';

class BookmarkCard extends StatefulWidget {
  const BookmarkCard({
    super.key,
    required this.bookmark,
    required this.onTap,
    this.onFetchTitle,
  });

  final BookmarkModel bookmark;
  final VoidCallback onTap;
  final VoidCallback? onFetchTitle;

  @override
  State<BookmarkCard> createState() => _BookmarkCardState();
}

class _BookmarkCardState extends State<BookmarkCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final motion = motionEnabled(context);

    return Semantics(
      label: '${widget.bookmark.title}, ${widget.bookmark.url}',
      button: true,
      child: AnimatedScale(
        scale: motion && _pressed ? 0.98 : 1,
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: motion
                ? (value) => setState(() => _pressed = value)
                : null,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedSwitcher(
                          duration: AppMotion.normal,
                          switchInCurve: AppMotion.decelerate,
                          switchOutCurve: AppMotion.standard,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.15),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            widget.bookmark.title,
                            key: ValueKey(widget.bookmark.title),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.bookmark.url,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusTrailing(
                    bookmark: widget.bookmark,
                    onFetchTitle: widget.onFetchTitle,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusTrailing extends StatelessWidget {
  const _StatusTrailing({
    required this.bookmark,
    this.onFetchTitle,
  });

  final BookmarkModel bookmark;
  final VoidCallback? onFetchTitle;

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (bookmark.fetchStatus == FetchStatus.pending) {
      child = const SizedBox(
        key: ValueKey('pending'),
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (bookmark.needsFetch && onFetchTitle != null) {
      child = IconButton(
        key: ValueKey('fetch-${bookmark.fetchStatus.name}'),
        tooltip: 'Fetch title',
        icon: Icon(
          bookmark.fetchStatus == FetchStatus.skippedOffline
              ? Icons.cloud_off
              : Icons.refresh,
        ),
        onPressed: onFetchTitle,
      );
    } else if (bookmark.fetchStatus == FetchStatus.failed) {
      child = Icon(
        key: const ValueKey('failed'),
        Icons.error_outline,
        color: Theme.of(context).colorScheme.error,
        size: 20,
      );
    } else {
      child = const SizedBox.shrink(key: ValueKey('idle'));
    }

    return AnimatedSwitcher(
      duration: AppMotion.fast,
      child: child,
    );
  }
}
