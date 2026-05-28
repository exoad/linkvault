import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_scope.dart';
import 'data/bookmark_repository.dart';
import 'data/note_repository.dart';
import 'features/hub/hub_screen.dart';
import 'theme/app_theme.dart';
import 'theme/linkvault_monochrome.dart';
import 'theme/system_ui.dart';
import 'theme/theme_controller.dart';

class LinkvaultApp extends StatelessWidget {
  const LinkvaultApp({
    super.key,
    required this.repository,
    required this.notes,
    required this.themeController,
  });

  final BookmarkRepository repository;
  final NoteRepository notes;
  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      repository: repository,
      notes: notes,
      child: ListenableBuilder(
        listenable: themeController,
        builder: (context, _) {
          final accent = themeController.accent;

          ThemeData themeFor(Brightness brightness) {
            return buildAppTheme(
              scheme: LinkvaultMonochrome.scheme(brightness),
              accent: accent,
            );
          }

          return MaterialApp(
            title: 'Linkvault',
            themeMode: themeController.themeMode,
            theme: themeFor(Brightness.light),
            darkTheme: themeFor(Brightness.dark),
            builder: (context, child) {
              final scheme = Theme.of(context).colorScheme;
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: overlayForScheme(scheme),
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: HubScreen(themeController: themeController),
          );
        },
      ),
    );
  }
}
