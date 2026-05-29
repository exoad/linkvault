import 'dart:io';

import 'package:flutter/material.dart';

import 'ai/chat/chat_hf_token_preferences.dart';
import 'ai/chat/chat_inference_preferences.dart';
import 'ai/chat/chat_service.dart';
import 'ai/chat/chat_session_preferences.dart';
import 'ai/runtime/inference_backend.dart';
import 'ai/tools/tool_registry.dart';
import 'app.dart';
import 'data/app_database.dart';
import 'data/bookmark_repository.dart';
import 'data/chat_repository.dart';
import 'data/note_repository.dart';
import 'platform/app_api.g.dart';
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
  final chat = ChatRepository(database: database);
  final backendPrefs = await InferenceBackendPreferences.load();
  final hfTokenPrefs = await ChatHfTokenPreferences.load();
  final chatInferencePrefs = await ChatInferencePreferences.load();
  final chatSessionPrefs = await ChatSessionPreferences.load();
  final chatService = ChatService.android(
    repository: chat,
    toolRegistry: ToolRegistry(),
    backendPrefs: backendPrefs,
    hfTokenPrefs: hfTokenPrefs,
    inferencePrefs: chatInferencePrefs,
    sessionPrefs: chatSessionPrefs,
  );
  final themeController = ThemeController();

  final navigatorKey = GlobalKey<NavigatorState>();
  final intentRouter = IntentRouter(navigatorKey: navigatorKey);
  intentRouter.attach();

  runApp(
    LinkvaultApp(
      database: database,
      repository: repository,
      notes: notes,
      chat: chat,
      chatService: chatService,
      themeController: themeController,
      navigatorKey: navigatorKey,
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (Platform.isAndroid) {
      try {
        UiHostApi().notifyUiReady();
      } catch (_) {
        // Host API unavailable outside Android embedding.
      }
    }
    intentRouter.handleInitialIntent();
  });
}
