import 'package:flutter/material.dart';

import '../theme/linkvault_typography.dart';
import 'linkvault_surface.dart';

/// Material 3 grouped settings block: label + flat bordered surface.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: LinkvaultTypography.sectionLabel(scheme),
          ),
        ),
        LinkvaultSurface(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _withDividers(children),
          ),
        ),
      ],
    );
  }

  List<Widget> _withDividers(List<Widget> items) {
    if (items.isEmpty) return items;
    final result = <Widget>[items.first];
    for (var i = 1; i < items.length; i++) {
      result.add(const Divider(height: 1, indent: 16, endIndent: 16));
      result.add(items[i]);
    }
    return result;
  }
}
