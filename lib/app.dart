import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_scope.dart';
import 'ai/chat/chat_service.dart';
import 'data/bookmark_repository.dart';
import 'data/chat_repository.dart';
import 'data/note_repository.dart';
import 'shell/app_shell.dart';
import 'theme/app_theme.dart';
import 'theme/linkvault_monochrome.dart';
import 'theme/system_ui.dart';
import 'theme/theme_controller.dart';
import 'widgets/linkvault_ambient_background.dart';

class LinkvaultApp extends StatelessWidget {
  const LinkvaultApp({
    super.key,
    required this.repository,
    required this.notes,
    required this.chat,
    required this.chatService,
    required this.themeController,
    this.navigatorKey,
  });

  final BookmarkRepository repository;
  final NoteRepository notes;
  final ChatRepository chat;
  final ChatService chatService;
  final ThemeController themeController;
  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  Widget build(BuildContext context) {
    final theme = buildAppTheme(
      scheme: LinkvaultMonochrome.dark,
      accent: themeController.accent,
    );

    return AppScope(
      repository: repository,
      notes: notes,
      chat: chat,
      chatService: chatService,
      child: MaterialApp(
        title: 'Linkvault',
        navigatorKey: navigatorKey,
        theme: theme,
        themeMode: ThemeMode.dark,
        builder: (context, child) {
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: overlayForScheme(theme.colorScheme),
            child: AmbientShell(
              key: const ValueKey('ambient-shell'),
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
        home: const AppShell(),
      ),
    );
  }
}
