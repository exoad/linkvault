import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../hub/hub_module.dart';
import '../theme/hub_app_colors.dart';
import '../theme/linkvault_accent.dart';
import '../theme/linkvault_design.dart';
import 'linkvault_animated_ambient.dart';
import 'linkvault_icon_chip.dart';
import 'linkvault_surface.dart';

/// Launcher tile for a hub app — accent on icon + stat only; layout cannot clip.
class HubAppTile extends StatelessWidget {
  const HubAppTile({
    super.key,
    required this.app,
    required this.statLabel,
    required this.onTap,
    required this.height,
  });

  final HubAppDefinition app;
  final String statLabel;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final phase = AmbientMotionScope.maybeOf(context);
    final accent = Theme.of(context).extension<LinkvaultAccent>();

    if (phase != null && accent != null) {
      return AnimatedBuilder(
        animation: phase,
        builder: (context, _) => _buildTile(
          context,
          HubAppColors.palette(accent, app, phase.value),
        ),
      );
    }

    final fallback = accent == null
        ? HubAppPalette(
            primary: app.seedPrimary,
            secondary: app.seedSecondary,
            tertiary: app.seedSecondary,
            glow: app.seedPrimary.withValues(alpha: 0.12),
          )
        : HubAppColors.palette(accent, app, 0);

    return _buildTile(context, fallback);
  }

  Widget _buildTile(BuildContext context, HubAppPalette colors) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: height,
      child: LinkvaultSurface(
        onTap: onTap,
        color: scheme.surfaceContainerLow,
        borderRadius: LinkvaultDesign.radiusHeroCard,
        padding: const EdgeInsets.all(LinkvaultDesign.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinkvaultIconChip(
              color: colors.primary,
              dimension: 52,
              child: PhosphorIcon(
                app.icon,
                size: 26,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: LinkvaultDesign.spaceMd),
            Text(
              app.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
            ),
            const Spacer(),
            _StatPill(label: statLabel, color: colors.primary),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LinkvaultDesign.spaceMd,
        vertical: LinkvaultDesign.spaceXs + 2,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: LinkvaultDesign.radiusControl,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
      ),
    );
  }
}

/// Grid cell height for hub launcher tiles.
double hubAppTileHeight(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  final tileWidth = (width - 16 * 2 - 12) / 2;
  return tileWidth * 1.12;
}
