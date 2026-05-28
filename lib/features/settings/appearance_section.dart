import 'package:flutter/material.dart';

import '../../theme/app_motion.dart';
import '../../theme/edge_glow_palette.dart';
import '../../theme/linkvault_gradients.dart';
import '../../theme/linkvault_design.dart';
import '../../theme/linkvault_typography.dart';
import '../../theme/theme_controller.dart';
import '../../widgets/settings_group.dart';
import '../../widgets/theme_mode_selector.dart';

class AppearanceSection extends StatelessWidget {
  const AppearanceSection({super.key, required this.themeController});

  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        final scheme = Theme.of(context).colorScheme;
        final selectedIndex = themeController.edgeGlowIndex;

        return SettingsGroup(
          title: 'Appearance',
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                LinkvaultDesign.spaceLg,
                LinkvaultDesign.spaceLg,
                LinkvaultDesign.spaceLg,
                LinkvaultDesign.spaceMd,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: LinkvaultDesign.spaceXs),
                  Text(
                    'Black and white UI · color on the edges only',
                    style: LinkvaultTypography.meta(scheme),
                  ),
                  const SizedBox(height: LinkvaultDesign.spaceLg),
                  ThemeModeSelector(
                    selected: themeController.themeMode,
                    onChanged: themeController.setThemeMode,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                LinkvaultDesign.spaceLg,
                LinkvaultDesign.spaceMd,
                LinkvaultDesign.spaceLg,
                LinkvaultDesign.spaceLg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edge glow',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: LinkvaultDesign.spaceXs),
                  Text(
                    'Soft bright accents along screen edges — not from wallpaper',
                    style: LinkvaultTypography.meta(scheme),
                  ),
                  const SizedBox(height: LinkvaultDesign.spaceLg),
                  Wrap(
                    spacing: 12,
                    runSpacing: 14,
                    children: List.generate(EdgeGlowPalette.presets.length, (i) {
                      final preset = EdgeGlowPalette.presets[i];
                      final selected = i == selectedIndex;
                      return GestureDetector(
                        onTap: () => themeController.setEdgeGlowIndex(i),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 52,
                              height: 52,
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selected
                                    ? scheme.surfaceContainerHighest
                                    : scheme.surfaceContainerLow,
                              ),
                              child: _EdgeGlowSwatch(
                                preset: preset,
                                animate: selected,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              preset.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: selected
                                        ? scheme.onSurface
                                        : scheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EdgeGlowSwatch extends StatefulWidget {
  const _EdgeGlowSwatch({required this.preset, required this.animate});

  final EdgeGlowPreset preset;
  final bool animate;

  @override
  State<_EdgeGlowSwatch> createState() => _EdgeGlowSwatchState();
}

class _EdgeGlowSwatchState extends State<_EdgeGlowSwatch>
    with SingleTickerProviderStateMixin {
  AnimationController? _spin;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncSpin();
  }

  @override
  void didUpdateWidget(covariant _EdgeGlowSwatch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate != widget.animate) {
      _syncSpin();
    }
  }

  void _syncSpin() {
    final shouldSpin =
        widget.animate && LinkvaultGradients.enabled(context);
    if (!shouldSpin) {
      _spin?.stop();
      return;
    }

    _spin ??= AnimationController(
      vsync: this,
      duration: AppMotion.ambientCycle,
    )..repeat();

    if (!_spin!.isAnimating) {
      _spin!.repeat();
    }
  }

  @override
  void dispose() {
    _spin?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = SweepGradient(
      colors: [
        widget.preset.primary,
        widget.preset.secondary,
        widget.preset.tertiary,
        widget.preset.primary,
      ],
    );

    final spin = _spin;
    if (spin == null) {
      return DecoratedBox(
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: gradient),
      );
    }

    return RotationTransition(
      turns: spin,
      child: DecoratedBox(
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: gradient),
      ),
    );
  }
}
