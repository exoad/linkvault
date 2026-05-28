import 'package:flutter/material.dart';

import '../models/bookmark.dart';
import '../models/fetch_status.dart';
import '../theme/app_motion.dart';
import '../theme/linkvault_design.dart';
import '../theme/linkvault_typography.dart';
import 'linkvault_surface.dart';

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
    final scheme = theme.colorScheme;
    final motion = motionEnabled(context);

    return Semantics(
      label: '${widget.bookmark.title}, ${widget.bookmark.url}',
      button: true,
      child: AnimatedScale(
        scale: motion && _pressed ? 0.98 : 1,
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        child: LinkvaultSurface(
          onTap: widget.onTap,
          onHighlightChanged: motion
              ? (value) => setState(() => _pressed = value)
              : null,
          child: Padding(
            padding: const EdgeInsets.all(LinkvaultDesign.spaceMd),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DomainAvatar(url: widget.bookmark.url),
                const SizedBox(width: LinkvaultDesign.spaceMd),
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
                      const SizedBox(height: LinkvaultDesign.spaceXs),
                      Text(
                        widget.bookmark.url,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: LinkvaultTypography.meta(scheme),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: LinkvaultDesign.spaceSm),
                _StatusTrailing(
                  bookmark: widget.bookmark,
                  onFetchTitle: widget.onFetchTitle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DomainAvatar extends StatelessWidget {
  const _DomainAvatar({required this.url});

  final String url;

  String get _initial {
    try {
      final host = Uri.parse(url).host;
      if (host.isEmpty) return '?';
      final label = host.startsWith('www.') ? host.substring(4) : host;
      return label[0].toUpperCase();
    } catch (_) {
      return '?';
    }
  }

  Color _tint(ColorScheme scheme) {
    final code = _initial.codeUnitAt(0);
    final hues = [scheme.primary, scheme.secondary, scheme.tertiary];
    return hues[code % hues.length];
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = _tint(scheme);
    return CircleAvatar(
      radius: 22,
      backgroundColor: tint.withValues(alpha: 0.2),
      child: Text(
        _initial,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: tint,
              fontWeight: FontWeight.w700,
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
