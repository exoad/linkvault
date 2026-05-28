import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../theme/folder_color_palette.dart';
import '../../theme/theme_controller.dart';
import '../../widgets/settings_group.dart';

class AppearanceSection extends StatelessWidget {
  const AppearanceSection({super.key, required this.themeController});

  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        return SettingsGroup(
          title: 'Appearance',
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: const Text('System'),
                    icon: PhosphorIcon(PhosphorIcons.deviceMobile),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: const Text('Light'),
                    icon: PhosphorIcon(PhosphorIcons.sun),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: const Text('Dark'),
                    icon: PhosphorIcon(PhosphorIcons.moon),
                  ),
                ],
                selected: {themeController.themeMode},
                onSelectionChanged: (modes) {
                  themeController.setThemeMode(modes.first);
                },
              ),
            ),
            SwitchListTile(
              title: const Text('Wallpaper colors'),
              subtitle: const Text(
                'Use system Material palette on Android 12+',
              ),
              secondary: PhosphorIcon(PhosphorIcons.palette),
              value: themeController.useDynamicColor,
              onChanged: themeController.setUseDynamicColor,
            ),
            if (!themeController.useDynamicColor)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Accent',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: ThemeSeedPalette.choices.map((color) {
                        final selected = color.toARGB32() ==
                            themeController.seedColor.toARGB32();
                        return GestureDetector(
                          onTap: () => themeController.setSeedColor(color),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                width: selected ? 3 : 1.5,
                                color: selected
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Theme.of(context)
                                        .colorScheme
                                        .outlineVariant,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            if (themeController.useDynamicColor)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  'Accent follows your wallpaper when the system provides a dynamic palette.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
          ],
        );
      },
    );
  }
}
