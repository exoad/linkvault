import 'package:flutter/material.dart';

import '../theme/linkvault_design.dart';
/// Standard bottom-sheet chrome: title, optional subtitle, scrollable body.
class LinkvaultSheetBody extends StatelessWidget {
  const LinkvaultSheetBody({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          LinkvaultDesign.spaceLg,
          LinkvaultDesign.spaceMd,
          LinkvaultDesign.spaceLg,
          LinkvaultDesign.spaceXl + bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            if (subtitle != null) ...[
              SizedBox(height: LinkvaultDesign.spaceSm),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ],
            SizedBox(height: LinkvaultDesign.spaceXl),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Padded row for settings sheets (slider, switch, etc.).
class LinkvaultSheetTile extends StatelessWidget {
  const LinkvaultSheetTile({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(
      horizontal: LinkvaultDesign.spaceLg,
      vertical: LinkvaultDesign.spaceMd,
    ),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(padding: padding, child: child);
  }
}
