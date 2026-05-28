import 'package:flutter/material.dart';

import 'data/bookmark_repository.dart';

class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.repository,
    required super.child,
  });

  final BookmarkRepository repository;

  static BookmarkRepository of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found');
    return scope!.repository;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      oldWidget.repository != repository;
}
