import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../hub/hub_module.dart';
import '../theme/linkvault_design.dart';
import '../theme/linkvault_typography.dart';
import 'linkvault_icon_chip.dart';
import 'linkvault_surface.dart';

/// Teaser row for a [HubModule] that is not launchable yet.
class HubComingSoonTile extends StatelessWidget {
  const HubComingSoonTile({super.key, required this.module});

  final HubModule module;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final app = module.definition;

    return LinkvaultSurface(
      color: scheme.surfaceContainerLow.withValues(alpha: 0.65),
      padding: const EdgeInsets.symmetric(
        horizontal: LinkvaultDesign.spaceLg,
        vertical: LinkvaultDesign.spaceMd,
      ),
      child: Row(
        children: [
          LinkvaultIconChip(
            color: scheme.onSurfaceVariant,
            dimension: 44,
            fill: 0.1,
            child: PhosphorIcon(
              app.icon,
              size: 22,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: LinkvaultDesign.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                Text(
                  app.description,
                  style: LinkvaultTypography.meta(scheme).copyWith(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: LinkvaultDesign.radiusControl,
            ),
            child: Text(
              'Soon',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
