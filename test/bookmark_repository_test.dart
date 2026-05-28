import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkvault/data/app_database.dart';
import 'package:linkvault/data/bookmark_repository.dart';
import 'package:linkvault/models/folder.dart';
import 'package:linkvault/services/connectivity_service.dart';

class _OfflineConnectivity extends ConnectivityService {
  @override
  Future<bool> isOnline() async => false;
}

FolderUpsert _upsert(String name) => FolderUpsert(
      name: name,
      colorValue: FolderModel.defaultColorValue,
      iconName: FolderModel.defaultIconName,
    );

void main() {
  late AppDatabase database;
  late BookmarkRepository repository;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    await database.ensureUnfiled();
    repository = BookmarkRepository(
      database: database,
      connectivityService: _OfflineConnectivity(),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('seeds Unfiled folder on ensure', () async {
    final folders = await repository.watchFolders().first;
    expect(folders.any((f) => f.name == FolderModel.unfiledName), isTrue);
    expect(folders.firstWhere((f) => f.isSystem).isSystem, isTrue);
  });

  test('addBookmark offline uses url as title', () async {
    final folderId = repository.unfiledFolderId;
    final bookmark = await repository.addBookmark(
      rawUrl: 'example.com',
      folderId: folderId,
    );
    expect(bookmark.title, bookmark.url);
    expect(bookmark.needsFetch, isTrue);
  });

  test('createFolder stores color and icon', () async {
    const color = 0xFF00AA55;
    const icon = 'bookmark';
    final folder = await repository.createFolder(
      FolderUpsert(
        name: 'Reading',
        colorValue: color,
        iconName: icon,
      ),
    );

    expect(folder.name, 'Reading');
    expect(folder.colorValue, color);
    expect(folder.iconName, icon);
    expect(folder.requiresUnlock, isFalse);

    final loaded = await repository.getFolder(folder.id);
    expect(loaded?.colorValue, color);
    expect(loaded?.iconName, icon);
  });

  test('updateFolder changes name color and icon', () async {
    final folder = await repository.createFolder(_upsert('Work'));
    await repository.updateFolder(
      folder.id,
      const FolderUpsert(
        name: 'Projects',
        colorValue: 0xFFFF0000,
        iconName: 'briefcase',
      ),
    );

    final updated = await repository.getFolder(folder.id);
    expect(updated?.name, 'Projects');
    expect(updated?.colorValue, 0xFFFF0000);
    expect(updated?.iconName, 'briefcase');
  });

  test('deleteFolder moves bookmarks to Unfiled', () async {
    final folder = await repository.createFolder(_upsert('Work'));
    await repository.addBookmark(
      rawUrl: 'https://example.com',
      folderId: folder.id,
    );
    await repository.deleteFolder(folder.id);

    final unfiledBookmarks =
        await repository.watchBookmarks(repository.unfiledFolderId).first;
    expect(unfiledBookmarks, hasLength(1));

    final folders = await repository.watchFolders().first;
    expect(folders.any((f) => f.name == 'Work'), isFalse);
  });

  test('cannot delete system folder', () async {
    expect(
      () => repository.deleteFolder(repository.unfiledFolderId),
      throwsStateError,
    );
  });

  test('locked folder requires unlock', () async {
    final folder = await repository.createFolder(
      FolderUpsert(
        name: 'Private',
        colorValue: FolderModel.defaultColorValue,
        iconName: 'lock',
        enableLock: true,
        pin: '1234',
      ),
    );
    expect(repository.canAccessFolder(folder), isFalse);
    final ok = await repository.unlockFolder(folder.id, '1234');
    expect(ok, isTrue);
    expect(repository.canAccessFolder(folder), isTrue);
  });

  test('unlock fails with wrong pin', () async {
    final folder = await repository.createFolder(
      FolderUpsert(
        name: 'Private',
        colorValue: FolderModel.defaultColorValue,
        iconName: 'lock',
        enableLock: true,
        pin: '1234',
      ),
    );
    final ok = await repository.unlockFolder(folder.id, '0000');
    expect(ok, isFalse);
    expect(repository.canAccessFolder(folder), isFalse);
  });

  test('addBookmark blocked while folder is locked', () async {
    final folder = await repository.createFolder(
      FolderUpsert(
        name: 'Private',
        colorValue: FolderModel.defaultColorValue,
        iconName: 'lock',
        enableLock: true,
        pin: '1234',
      ),
    );

    expect(
      () => repository.addBookmark(
        rawUrl: 'https://example.com',
        folderId: folder.id,
      ),
      throwsStateError,
    );

    await repository.unlockFolder(folder.id, '1234');
    final bookmark = await repository.addBookmark(
      rawUrl: 'https://example.com',
      folderId: folder.id,
    );
    expect(bookmark.folderId, folder.id);
  });

  test('lockFolder clears session access', () async {
    final folder = await repository.createFolder(
      FolderUpsert(
        name: 'Private',
        colorValue: FolderModel.defaultColorValue,
        iconName: 'lock',
        enableLock: true,
        pin: '1234',
      ),
    );
    await repository.unlockFolder(folder.id, '1234');
    expect(repository.canAccessFolder(folder), isTrue);

    repository.lockFolder(folder.id);
    expect(repository.canAccessFolder(folder), isFalse);
  });
}
