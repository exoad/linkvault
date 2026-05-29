import 'package:flutter/material.dart';

import '../animations/interaction_motion.dart';
import '../models/bookmark.dart';
import '../models/fetch_status.dart';
import '../theme/app_motion.dart';
import '../theme/ambient_lava_palette.dart';
import '../theme/linkvault_design.dart';
import '../theme/linkvault_typography.dart';
import 'linkvault_animated_ambient.dart';
import 'linkvault_icon_chip.dart';
import 'linkvault_surface.dart';

class BookmarkCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      label: '${bookmark.title}, ${bookmark.url}',
      button: true,
      child: LinkvaultSurface(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(LinkvaultDesign.spaceLg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DomainAvatar(url: bookmark.url),
              const SizedBox(width: LinkvaultDesign.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    aliveFadeSwap(
                      value: bookmark.title,
                      child: Text(
                        bookmark.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: LinkvaultDesign.spaceXs),
                    Text(
                      bookmark.url,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: LinkvaultTypography.meta(scheme),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: LinkvaultDesign.spaceSm),
              _StatusTrailing(
                bookmark: bookmark,
                onFetchTitle: onFetchTitle,
              ),
            ],
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

  Color _tint(ColorScheme scheme, double? phase) {
    if (phase != null) {
      return AmbientLavaPalette.colorAt(phase + _initial.codeUnitAt(0) * 0.07);
    }
    return scheme.onSurface.withValues(alpha: 0.5);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final phase = AmbientMotionScope.maybeOf(context)?.value;
    final tint = _tint(scheme, phase);
    return LinkvaultIconChip(
      color: tint,
      dimension: 48,
      child: Text(
        _initial,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: tint,
              fontWeight: FontWeight.w700,
              fontSize: 20,
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
      duration: AppMotion.normal,
      switchInCurve: AppMotion.decelerate,
      switchOutCurve: AppMotion.standard,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1).animate(animation),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
