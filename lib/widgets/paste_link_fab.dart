import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../theme/linkvault_accent.dart';
import '../theme/linkvault_gradients.dart';

/// Primary paste action — static layout (no entrance animation on rebuild).
class PasteLinkFab extends StatelessWidget {
  const PasteLinkFab({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).extension<LinkvaultAccent>();

    final fab = FloatingActionButton.extended(
      onPressed: onPressed,
      icon: PhosphorIcon(PhosphorIcons.link, size: 22),
      label: const Text(
        'Paste link',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    );

    if (accent == null) return fab;

    return AmbientAwareFabGlow(accent: accent, child: fab);
  }
}
