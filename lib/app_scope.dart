import 'package:flutter/material.dart';

import 'data/bookmark_repository.dart';
import 'data/note_repository.dart';

class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.repository,
    required this.notes,
    required super.child,
  });

  final BookmarkRepository repository;
  final NoteRepository notes;

  static AppScope _scope(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found');
    return scope!;
  }

  /// Bookmark / links repository.
  static BookmarkRepository of(BuildContext context) => _scope(context).repository;

  static BookmarkRepository bookmarksOf(BuildContext context) =>
      of(context);

  static NoteRepository notesOf(BuildContext context) => _scope(context).notes;

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      oldWidget.repository != repository || oldWidget.notes != notes;
}
