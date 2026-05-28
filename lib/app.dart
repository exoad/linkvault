import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_scope.dart';
import 'data/bookmark_repository.dart';
import 'features/folders/folders_screen.dart';
import 'theme/app_theme.dart';
import 'theme/system_ui.dart';
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

              ThemeData themeFor(Brightness brightness, ColorScheme? dynamic) {
                final scheme = useDynamic && dynamic != null
                    ? dynamic
                    : colorSchemeFromSeed(
                        seedColor: seed,
                        brightness: brightness,
                      );
                return buildAppTheme(scheme);
              }

              final lightTheme = themeFor(Brightness.light, lightDynamic);
              final darkTheme = themeFor(Brightness.dark, darkDynamic);

              return MaterialApp(
                title: 'Linkvault',
                themeMode: themeController.themeMode,
                theme: lightTheme,
                darkTheme: darkTheme,
                builder: (context, child) {
                  final scheme = Theme.of(context).colorScheme;
                  return AnnotatedRegion<SystemUiOverlayStyle>(
                    value: overlayForScheme(scheme),
                    child: child ?? const SizedBox.shrink(),
                  );
                },
                home: FoldersScreen(themeController: themeController),
              );
            },
          );
        },
      ),
    );
  }
}
