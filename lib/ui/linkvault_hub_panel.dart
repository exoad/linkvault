import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../hub/hub_module.dart';
import '../theme/hub_app_colors.dart';
import '../theme/linkvault_design.dart';
import '../widgets/linkvault_animated_ambient.dart';
import '../widgets/linkvault_icon_chip.dart';
import '../widgets/linkvault_surface.dart';

/// Centered hub-style panel for empty, download, and error states.
class LinkvaultHubPanel extends StatelessWidget {
  const LinkvaultHubPanel({
    super.key,
    required this.app,
    required this.icon,
    required this.title,
    this.subtitle,
    this.errorMessage,
    this.child,
    this.primaryAction,
    this.pulsing = false,
  });

  final HubAppDefinition app;
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? errorMessage;
  final Widget? child;
  final Widget? primaryAction;
  final bool pulsing;

  @override
  Widget build(BuildContext context) {
    final phase = AmbientMotionScope.maybeOf(context)?.value ?? 0.0;
    final hub = HubAppColors.palette(app, phase);
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LinkvaultDesign.spaceXl),
        child: LinkvaultSurface(
          tinted: true,
          borderRadius: LinkvaultDesign.radiusHeroCard,
          padding: const EdgeInsets.symmetric(
            horizontal: LinkvaultDesign.spaceXl,
            vertical: LinkvaultDesign.space2xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinkvaultIconChip(
                dimension: 56,
                color: hub.primary,
                child: PhosphorIcon(icon, color: hub.primary, size: 28),
              ),
              SizedBox(height: LinkvaultDesign.spaceLg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: hub.secondary.withValues(alpha: 0.95),
                ),
              ),
              if (subtitle != null) ...[
                SizedBox(height: LinkvaultDesign.spaceSm),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.65),
                    height: 1.4,
                  ),
                ),
              ],
              if (errorMessage != null) ...[
                SizedBox(height: LinkvaultDesign.spaceMd),
                Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.error),
                ),
              ],
              if (child != null) ...[
                SizedBox(height: LinkvaultDesign.spaceLg),
                child!,
              ],
              if (primaryAction != null) ...[
                SizedBox(height: LinkvaultDesign.spaceXl),
                primaryAction!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Small circular loader tinted with hub accent.
class LinkvaultHubLoader extends StatelessWidget {
  const LinkvaultHubLoader({super.key, required this.app});

  final HubAppDefinition app;

  @override
  Widget build(BuildContext context) {
    final phase = AmbientMotionScope.maybeOf(context)?.value ?? 0.0;
    final hub = HubAppColors.palette(app, phase);

    return Center(
      child: SizedBox(
        width: 48,
        height: 48,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: hub.primary,
        ),
      ),
    );
  }
}
