import 'package:flutter/material.dart';

import 'ai/chat/chat_service.dart';
import 'data/app_database.dart';
import 'data/bookmark_repository.dart';
import 'data/chat_repository.dart';
import 'data/note_repository.dart';

class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.database,
    required this.repository,
    required this.notes,
    required this.chat,
    required this.chatService,
    required super.child,
  });

  final AppDatabase database;
  final BookmarkRepository repository;
  final NoteRepository notes;
  final ChatRepository chat;
  final ChatService chatService;

  static AppScope _scope(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found');
    return scope!;
  }

  /// Bookmark / links repository.
  static AppDatabase databaseOf(BuildContext context) =>
      _scope(context).database;

  static BookmarkRepository of(BuildContext context) => _scope(context).repository;

  static BookmarkRepository bookmarksOf(BuildContext context) =>
      of(context);

  static NoteRepository notesOf(BuildContext context) => _scope(context).notes;

  static ChatRepository chatOf(BuildContext context) => _scope(context).chat;

  static ChatService chatServiceOf(BuildContext context) =>
      _scope(context).chatService;

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      oldWidget.database != database ||
      oldWidget.repository != repository ||
      oldWidget.notes != notes ||
      oldWidget.chat != chat ||
      oldWidget.chatService != chatService;
}
