import 'package:flutter/material.dart';

import '../theme/linkvault_design.dart';
import '../theme/linkvault_typography.dart';

/// Large expressive header for the home hub screen.
class HubHeroHeader extends StatelessWidget {
  const HubHeroHeader({
    super.key,
    this.title = 'Your hub',
    this.subtitle = 'Apps on this device · open one below',
    this.statLabel,
  });

  final String title;
  final String subtitle;
  final String? statLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: LinkvaultTypography.hubTitle(scheme)),
        const SizedBox(height: LinkvaultDesign.spaceSm),
        Text(subtitle, style: LinkvaultTypography.hubSubtitle(scheme)),
        if (statLabel != null) ...[
          const SizedBox(height: LinkvaultDesign.spaceLg),
          _StatChip(label: statLabel!),
        ],
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LinkvaultDesign.spaceLg,
        vertical: LinkvaultDesign.spaceSm + 2,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: LinkvaultDesign.radiusControl,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
