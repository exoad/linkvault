import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkvault/data/app_database.dart';
import 'package:linkvault/models/fetch_status.dart';
import 'package:linkvault/models/folder.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  test('upgrade from schema 1 to 2 preserves folders and bookmarks', () async {
    final underlying = sqlite.sqlite3.openInMemory();

    underlying.execute('''
      CREATE TABLE folders (
        id TEXT NOT NULL PRIMARY KEY,
        name TEXT NOT NULL,
        is_system INTEGER NOT NULL DEFAULT 0 CHECK (is_system IN (0, 1)),
        created_at INTEGER NOT NULL
      );
    ''');
    underlying.execute('''
      CREATE TABLE bookmarks (
        id TEXT NOT NULL PRIMARY KEY,
        folder_id TEXT NOT NULL REFERENCES folders(id),
        url TEXT NOT NULL,
        title TEXT NOT NULL,
        fetch_status TEXT NOT NULL,
        fetched_at INTEGER,
        created_at INTEGER NOT NULL
      );
    ''');

    const folderId = 'folder-1';
    const bookmarkId = 'bookmark-1';
    final createdAt = DateTime.utc(2024, 1, 1).millisecondsSinceEpoch;

    underlying.execute(
      "INSERT INTO folders (id, name, is_system, created_at) "
      "VALUES ('$folderId', 'Work', 0, $createdAt);",
    );
    underlying.execute(
      "INSERT INTO bookmarks (id, folder_id, url, title, fetch_status, created_at) "
      "VALUES ('$bookmarkId', '$folderId', 'https://example.com', 'Example', 'success', $createdAt);",
    );

    underlying.userVersion = 1;

    final upgraded = AppDatabase.forTesting(
      NativeDatabase.opened(underlying),
    );
    await upgraded.ensureUnfiled();

    final folder = await upgraded.getFolderById(folderId);
    expect(folder, isNotNull);
    expect(folder!.name, 'Work');
    expect(folder.colorValue, FolderModel.defaultColorValue);
    expect(folder.iconName, FolderModel.defaultIconName);
    expect(folder.isLocked, isFalse);

    final bookmark = await upgraded.getBookmarkById(bookmarkId);
    expect(bookmark, isNotNull);
    expect(bookmark!.url, 'https://example.com');
    expect(bookmark.title, 'Example');

    await upgraded.close();
  });

  test('ensureUnfiled does not remove user bookmarks', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.ensureUnfiled();

    final folder = await db.insertFolder(
      name: 'Personal',
      colorValue: FolderModel.defaultColorValue,
      iconName: FolderModel.defaultIconName,
    );
    await db.insertBookmark(
      folderId: folder.id,
      url: 'https://keep.me',
      title: 'Keep me',
      fetchStatus: FetchStatus.success,
    );

    await db.ensureUnfiled();

    final bookmarks = await db.watchBookmarksInFolder(folder.id).first;
    expect(bookmarks, hasLength(1));
    expect(bookmarks.first.url, 'https://keep.me');

    await db.close();
  });
}
