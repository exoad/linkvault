import 'package:flutter/material.dart';

import 'app.dart';
import 'data/app_database.dart';
import 'data/bookmark_repository.dart';
import 'data/note_repository.dart';
import 'services/display_mode_service.dart';
import 'services/intent_router.dart';
import 'theme/system_ui.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureEdgeToEdge();
  await DisplayModeService.ensureHighRefreshRate();

  final database = AppDatabase();
  await database.ensureUnfiled();
  final repository = BookmarkRepository(database: database);
  final notes = NoteRepository(database: database);
  final themeController = ThemeController();
  await themeController.load();

  final navigatorKey = GlobalKey<NavigatorState>();
  final intentRouter = IntentRouter(navigatorKey: navigatorKey);
  intentRouter.attach();

  runApp(
    LinkvaultApp(
      repository: repository,
      notes: notes,
      themeController: themeController,
      navigatorKey: navigatorKey,
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback(
    (_) => intentRouter.handleInitialIntent(),
  );
}
