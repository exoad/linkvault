import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

import 'app_scope.dart';
import 'data/bookmark_repository.dart';
import 'features/folders/folders_screen.dart';
import 'theme/theme_controller.dart';

class LinkvaultApp extends StatelessWidget {
  const LinkvaultApp({
    super.key,
    required this.repository,
    required this.themeController,
  });

  final BookmarkRepository repository;
  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      repository: repository,
      child: ListenableBuilder(
        listenable: themeController,
        builder: (context, _) {
          return DynamicColorBuilder(
            builder: (lightDynamic, darkDynamic) {
              final useDynamic = themeController.useDynamicColor;
              final seed = themeController.seedColor;

              ThemeData buildTheme(Brightness brightness, ColorScheme? dynamic) {
                final scheme = useDynamic && dynamic != null
                    ? dynamic
                    : ColorScheme.fromSeed(
                        seedColor: seed,
                        brightness: brightness,
                      );
                return ThemeData(
                  colorScheme: scheme,
                  useMaterial3: true,
                  pageTransitionsTheme: const PageTransitionsTheme(
                    builders: {
                      TargetPlatform.android:
                          FadeUpwardsPageTransitionsBuilder(),
                    },
                  ),
                );
              }

              return MaterialApp(
                title: 'Linkvault',
                themeMode: themeController.themeMode,
                theme: buildTheme(Brightness.light, lightDynamic),
                darkTheme: buildTheme(Brightness.dark, darkDynamic),
                home: FoldersScreen(themeController: themeController),
              );
            },
          );
        },
      ),
    );
  }
}
