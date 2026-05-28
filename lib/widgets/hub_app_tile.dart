import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../hub/hub_module.dart';
import '../theme/hub_app_colors.dart';
import '../theme/linkvault_accent.dart';
import '../theme/linkvault_design.dart';
import '../theme/linkvault_typography.dart';
import 'linkvault_animated_ambient.dart';
import 'linkvault_surface.dart';

/// Launcher tile for a hub app — living gradient tied to edge glow motion.
class HubAppTile extends StatelessWidget {
  const HubAppTile({
    super.key,
    required this.app,
    required this.statLabel,
    required this.onTap,
  });

  final HubAppDefinition app;
  final String statLabel;
  final VoidCallback onTap;

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
            glow: app.seedPrimary.withValues(alpha: 0.25),
          )
        : HubAppColors.palette(accent, app, 0);

    return _buildTile(context, fallback);
  }

  Widget _buildTile(BuildContext context, HubAppPalette colors) {
    final scheme = Theme.of(context).colorScheme;

    return LinkvaultSurface(
      onTap: onTap,
      color: scheme.surfaceContainerLow,
      borderRadius: LinkvaultDesign.radiusHeroCard,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: LinkvaultDesign.radiusHeroCard,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colors.primary.withValues(alpha: 0.42),
                      colors.secondary.withValues(alpha: 0.28),
                      colors.tertiary.withValues(alpha: 0.12),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: -24,
              top: -24,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colors.glow,
                      blurRadius: 48,
                      spreadRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(LinkvaultDesign.spaceLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: colors.primary.withValues(alpha: 0.22),
                    child: PhosphorIcon(
                      app.icon,
                      size: 30,
                      color: colors.primary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    app.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: LinkvaultDesign.spaceXs),
                  Text(
                    app.description,
                    style: LinkvaultTypography.meta(scheme),
                  ),
                  const SizedBox(height: LinkvaultDesign.spaceMd),
                  _StatPill(label: statLabel, color: colors.primary),
                ],
              ),
            ),
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
        color: scheme.surface.withValues(alpha: 0.72),
        borderRadius: LinkvaultDesign.radiusControl,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
      ),
    );
  }
}

/// Fixed aspect launcher grid cell height helper.
double hubAppTileHeight(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  final tileWidth = (width - 16 * 2 - 12) / 2;
  return tileWidth * 1.05;
}
