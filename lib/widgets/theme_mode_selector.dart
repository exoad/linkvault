import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../theme/linkvault_design.dart';

/// Theme mode picker: three spacious tiles (icon above label).
class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final ThemeMode selected;
  final ValueChanged<ThemeMode> onChanged;

  static const _options = [
    (
      ThemeMode.system,
      'System',
      PhosphorIcons.deviceMobile,
      'Match device',
    ),
    (ThemeMode.light, 'Light', PhosphorIcons.sun, 'White surfaces'),
    (ThemeMode.dark, 'Dark', PhosphorIcons.moon, 'Black surfaces'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _options.length; i++) ...[
          if (i > 0) const SizedBox(width: LinkvaultDesign.spaceSm),
          Expanded(
            child: _ThemeModeTile(
              label: _options[i].$2,
              icon: _options[i].$3,
              hint: _options[i].$4,
              selected: selected == _options[i].$1,
              onTap: () => onChanged(_options[i].$1),
            ),
          ),
        ],
      ],
    );
  }
}

class _ThemeModeTile extends StatelessWidget {
  const _ThemeModeTile({
    required this.label,
    required this.icon,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: '$label theme, $hint',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: LinkvaultDesign.radiusControl,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(
              horizontal: LinkvaultDesign.spaceSm,
              vertical: LinkvaultDesign.spaceLg,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? scheme.surfaceContainerHighest
                  : scheme.surfaceContainerLow,
              borderRadius: LinkvaultDesign.radiusControl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PhosphorIcon(
                  icon,
                  size: 26,
                  color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                ),
                const SizedBox(height: LinkvaultDesign.spaceMd),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                ),
                const SizedBox(height: LinkvaultDesign.spaceXs),
                Text(
                  hint,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        height: 1.25,
                        color: scheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
