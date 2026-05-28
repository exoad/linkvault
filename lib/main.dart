import 'package:flutter/material.dart';

import 'app.dart';
import 'data/app_database.dart';
import 'data/bookmark_repository.dart';
import 'services/display_mode_service.dart';
import 'theme/system_ui.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureEdgeToEdge();
  await DisplayModeService.ensureHighRefreshRate();

  final database = AppDatabase();
  await database.ensureUnfiled();
  final repository = BookmarkRepository(database: database);
  final themeController = ThemeController();
  await themeController.load();

  runApp(
    LinkvaultApp(
      repository: repository,
      themeController: themeController,
    ),
  );
}
