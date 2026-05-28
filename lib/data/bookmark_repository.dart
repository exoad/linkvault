import '../models/bookmark.dart';
import '../models/fetch_status.dart';
import '../models/folder.dart';
import '../services/connectivity_service.dart';
import '../services/folder_lock_session.dart';
import '../services/metadata_service.dart';
import '../services/pin_service.dart';
import '../services/url_normalizer.dart';
import 'app_database.dart';

class FolderUpsert {
  const FolderUpsert({
    required this.name,
    required this.colorValue,
    required this.iconName,
    this.enableLock = false,
    this.pin,
    this.removeLock = false,
  });

  final String name;
  final int colorValue;
  final String iconName;
  final bool enableLock;
  final String? pin;
  final bool removeLock;
}

class BookmarkRepository {
  BookmarkRepository({
    required AppDatabase database,
    MetadataService? metadataService,
    ConnectivityService? connectivityService,
    FolderLockSession? lockSession,
  })  : _db = database,
        _metadata = metadataService ?? MetadataService(),
        _connectivity = connectivityService ?? ConnectivityService(),
        _lockSession = lockSession ?? FolderLockSession();

  final AppDatabase _db;
  final MetadataService _metadata;
  final ConnectivityService _connectivity;
  final FolderLockSession _lockSession;

  FolderLockSession get lockSession => _lockSession;

  String get unfiledFolderId => _db.unfiledFolderId;

  bool canAccessFolder(FolderModel folder) {
    if (!folder.requiresUnlock) return true;
    return _lockSession.isUnlocked(folder.id);
  }

  Future<bool> unlockFolder(String folderId, String pin) async {
    final row = await _db.getFolderById(folderId);
    if (row == null) return false;
    if (row.pinSalt == null || row.pinHash == null) return false;
    final ok = PinService.verifyPin(
      pin: pin,
      salt: row.pinSalt!,
      storedHash: row.pinHash!,
    );
    if (ok) _lockSession.unlock(folderId);
    return ok;
  }

  void lockFolder(String folderId) => _lockSession.lock(folderId);

  Stream<List<FolderModel>> watchFolders() {
    return _db.watchFoldersWithCounts().map(
          (rows) => rows.map(_folderFromRow).toList(),
        );
  }

  Stream<List<BookmarkModel>> watchBookmarks(String folderId) {
    return _db.watchBookmarksInFolder(folderId).map(
          (rows) => rows.map(_toModel).toList(),
        );
  }

  Future<FolderModel?> getFolder(String id) async {
    final row = await _db.getFolderById(id);
    if (row == null) return null;
    return _folderFromData(row);
  }

  Future<BookmarkModel> addBookmark({
    required String rawUrl,
    required String folderId,
  }) async {
    final folder = await getFolder(folderId);
    if (folder != null && !canAccessFolder(folder)) {
      throw StateError('Folder is locked');
    }

    final url = UrlNormalizer.normalize(rawUrl);
    if (url == null) {
      throw ArgumentError('Invalid URL');
    }

    final online = await _connectivity.isOnline();
    final initialStatus =
        online ? FetchStatus.pending : FetchStatus.skippedOffline;

    final row = await _db.insertBookmark(
      folderId: folderId,
      url: url,
      title: url,
      fetchStatus: initialStatus,
    );

    final model = _toModel(row);
    if (online) {
      fetchMetadataForBookmark(model.id);
    }
    return model;
  }

  Future<void> fetchMetadataForBookmark(String bookmarkId) async {
    final row = await _db.getBookmarkById(bookmarkId);
    if (row == null) return;

    final online = await _connectivity.isOnline();
    if (!online) {
      await _db.updateBookmarkRow(
        id: bookmarkId,
        fetchStatus: FetchStatus.skippedOffline,
      );
      return;
    }

    await _db.updateBookmarkRow(
      id: bookmarkId,
      fetchStatus: FetchStatus.pending,
    );

    final title = await _metadata.fetchTitle(row.url);
    if (title != null && title.isNotEmpty) {
      await _db.updateBookmarkRow(
        id: bookmarkId,
        title: title,
        fetchStatus: FetchStatus.success,
        fetchedAt: DateTime.now(),
      );
    } else {
      await _db.updateBookmarkRow(
        id: bookmarkId,
        title: row.url,
        fetchStatus: FetchStatus.failed,
        clearFetchedAt: true,
      );
    }
  }

  Future<bool> tryFetchMetadataForBookmark(String bookmarkId) async {
    final online = await _connectivity.isOnline();
    if (!online) return false;
    await fetchMetadataForBookmark(bookmarkId);
    return true;
  }

  Future<void> updateBookmark({
    required String id,
    String? rawUrl,
    String? title,
    String? folderId,
  }) async {
    String? url;
    if (rawUrl != null) {
      url = UrlNormalizer.normalize(rawUrl);
      if (url == null) throw ArgumentError('Invalid URL');
    }

    if (folderId != null) {
      final target = await getFolder(folderId);
      if (target != null && !canAccessFolder(target)) {
        throw StateError('Target folder is locked');
      }
    }

    await _db.updateBookmarkRow(
      id: id,
      url: url,
      title: title?.trim(),
      folderId: folderId,
    );
  }

  Future<void> deleteBookmark(String id) async {
    await _db.deleteBookmark(id);
  }

  Future<FolderModel> createFolder(FolderUpsert input) async {
    _validateFolderInput(input);
    final pinCreds = _pinCredentials(input);

    final row = await _db.insertFolder(
      name: input.name,
      colorValue: input.colorValue,
      iconName: input.iconName,
      isLocked: pinCreds != null,
      pinSalt: pinCreds?.$1,
      pinHash: pinCreds?.$2,
    );
    return _folderFromData(row);
  }

  Future<void> updateFolder(String id, FolderUpsert input) async {
    final folder = await _db.getFolderById(id);
    if (folder == null) throw StateError('Folder not found');
    if (folder.isSystem) throw StateError('Cannot edit system folder');
    final hasExistingPin = folder.pinHash != null && folder.pinHash!.isNotEmpty;
    _validateFolderInput(
      input,
      allowEmptyPin: hasExistingPin && input.pin == null,
    );

    String? salt;
    String? hash;
    var clearPin = false;
    var isLocked = folder.isLocked;

    if (input.removeLock) {
      clearPin = true;
      isLocked = false;
      _lockSession.lock(id);
    } else if (input.enableLock && input.pin != null) {
      final creds = _pinCredentials(input);
      salt = creds!.$1;
      hash = creds.$2;
      isLocked = true;
    } else if (input.enableLock && folder.pinHash != null) {
      isLocked = true;
    } else if (!input.enableLock) {
      isLocked = false;
      clearPin = folder.pinHash != null;
      _lockSession.lock(id);
    }

    await _db.updateFolder(
      id: id,
      name: input.name,
      colorValue: input.colorValue,
      iconName: input.iconName,
      isLocked: isLocked,
      pinSalt: salt,
      pinHash: hash,
      clearPin: clearPin,
    );
  }

  Future<void> deleteFolder(String id) async {
    final folder = await _db.getFolderById(id);
    if (folder == null) return;
    if (folder.isSystem) throw StateError('Cannot delete system folder');

    await _db.moveBookmarksToFolder(id, _db.unfiledFolderId);
    await _db.deleteFolder(id);
    _lockSession.lock(id);
  }

  void _validateFolderInput(FolderUpsert input, {bool allowEmptyPin = false}) {
    if (input.name.trim().isEmpty) {
      throw ArgumentError('Folder name cannot be empty');
    }
    if (input.enableLock && !input.removeLock) {
      if (input.pin != null &&
          input.pin!.isNotEmpty &&
          !PinService.isValidPinFormat(input.pin!)) {
        throw ArgumentError('PIN must be 4 digits');
      }
      if (!allowEmptyPin &&
          (input.pin == null || input.pin!.isEmpty)) {
        throw ArgumentError('PIN required when lock is enabled');
      }
    }
  }

  (String, String)? _pinCredentials(FolderUpsert input) {
    if (!input.enableLock || input.removeLock) return null;
    if (input.pin == null || input.pin!.isEmpty) return null;
    final salt = PinService.generateSalt();
    final hash = PinService.hashPin(input.pin!, salt);
    return (salt, hash);
  }

  FolderModel _folderFromRow(FolderWithCount row) {
    return FolderModel(
      id: row.id,
      name: row.name,
      isSystem: row.isSystem,
      createdAt: row.createdAt,
      colorValue: row.colorValue,
      iconName: row.iconName,
      isLocked: row.isLocked,
      hasPin: row.hasPin,
      bookmarkCount: row.bookmarkCount,
    );
  }

  FolderModel _folderFromData(Folder row) {
    return FolderModel(
      id: row.id,
      name: row.name,
      isSystem: row.isSystem,
      createdAt: row.createdAt,
      colorValue: row.colorValue,
      iconName: row.iconName,
      isLocked: row.isLocked,
      hasPin: row.pinHash != null && row.pinHash!.isNotEmpty,
    );
  }

  BookmarkModel _toModel(Bookmark row) {
    return BookmarkModel(
      id: row.id,
      folderId: row.folderId,
      url: row.url,
      title: row.title,
      fetchStatus: FetchStatusX.fromStorage(row.fetchStatus),
      fetchedAt: row.fetchedAt,
      createdAt: row.createdAt,
    );
  }
}
