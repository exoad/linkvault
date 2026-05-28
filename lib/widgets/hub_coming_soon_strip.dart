import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../theme/linkvault_design.dart';
import '../theme/linkvault_typography.dart';
import 'linkvault_surface.dart';

/// Muted placeholder for future hub modules (non-interactive).
class HubComingSoonStrip extends StatelessWidget {
  const HubComingSoonStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return LinkvaultSurface(
      color: scheme.surfaceContainerLowest,
      padding: const EdgeInsets.symmetric(
        horizontal: LinkvaultDesign.spaceLg,
        vertical: LinkvaultDesign.spaceMd + 2,
      ),
      child: Row(
        children: [
          PhosphorIcon(
            PhosphorIcons.notePencil,
            size: 22,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
          const SizedBox(width: LinkvaultDesign.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notes & thoughts',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface.withValues(alpha: 0.75),
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Coming soon',
                  style: LinkvaultTypography.meta(scheme),
                ),
              ],
            ),
          ),
          Text(
            'Soon',
            style: LinkvaultTypography.sectionLabel(scheme).copyWith(
              color: scheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}
