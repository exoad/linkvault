import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../theme/folder_color_palette.dart';
import '../../theme/theme_controller.dart';
import 'update_section.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.themeController});

  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListenableBuilder(
        listenable: themeController,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const UpdateSection(),
              const SizedBox(height: 32),
              Text(
                'Appearance',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              SegmentedButton<ThemeMode>(
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
              const SizedBox(height: 24),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Use system Material colors'),
                subtitle: const Text(
                  'Match wallpaper / system palette on Android 12+',
                ),
                secondary: PhosphorIcon(PhosphorIcons.palette),
                value: themeController.useDynamicColor,
                onChanged: themeController.setUseDynamicColor,
              ),
              if (!themeController.useDynamicColor) ...[
                const SizedBox(height: 16),
                Text(
                  'Accent color',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ThemeSeedPalette.choices.map((color) {
                    final selected =
                        color.toARGB32() == themeController.seedColor.toARGB32();
                    return GestureDetector(
                      onTap: () => themeController.setSeedColor(color),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            width: selected ? 3 : 1,
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
              if (themeController.useDynamicColor) ...[
                const SizedBox(height: 16),
                Text(
                  'On Android 12+, accent colors follow your wallpaper when available.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
