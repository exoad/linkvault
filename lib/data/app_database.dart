import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/fetch_status.dart';
import '../models/folder.dart';

part 'app_database.g.dart';

class Folders extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();
  IntColumn get colorValue =>
      integer().withDefault(const Constant(FolderModel.defaultColorValue))();
  TextColumn get iconName =>
      text().withDefault(const Constant(FolderModel.defaultIconName))();
  BoolColumn get isLocked => boolean().withDefault(const Constant(false))();
  TextColumn get pinSalt => text().nullable()();
  TextColumn get pinHash => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Bookmarks extends Table {
  TextColumn get id => text()();
  TextColumn get folderId => text().references(Folders, #id)();
  TextColumn get url => text()();
  TextColumn get title => text()();
  TextColumn get fetchStatus => text()();
  DateTimeColumn get fetchedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Folders, Bookmarks])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  static const _unfiledId = 'system-unfiled';

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _seedUnfiled();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.addColumn(folders, folders.colorValue);
            await m.addColumn(folders, folders.iconName);
            await m.addColumn(folders, folders.isLocked);
            await m.addColumn(folders, folders.pinSalt);
            await m.addColumn(folders, folders.pinHash);
          }
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'linkvault');
  }

  Future<void> _seedUnfiled() async {
    await into(folders).insert(
      FoldersCompanion.insert(
        id: _unfiledId,
        name: FolderModel.unfiledName,
        isSystem: const Value(true),
        createdAt: DateTime.now(),
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<void> ensureUnfiled() => _seedUnfiled();

  String get unfiledFolderId => _unfiledId;

  Stream<List<FolderWithCount>> watchFoldersWithCounts() {
    final bookmarkCount = bookmarks.id.count();
    final query = select(folders).join([
      leftOuterJoin(
        bookmarks,
        bookmarks.folderId.equalsExp(folders.id),
      ),
    ]);
    query
      ..addColumns([bookmarkCount])
      ..groupBy([folders.id])
      ..orderBy([
        OrderingTerm.asc(folders.isSystem),
        OrderingTerm.asc(folders.name),
      ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        final folder = row.readTable(folders);
        return FolderWithCount(
          id: folder.id,
          name: folder.name,
          isSystem: folder.isSystem,
          createdAt: folder.createdAt,
          colorValue: folder.colorValue,
          iconName: folder.iconName,
          isLocked: folder.isLocked,
          hasPin: folder.pinHash != null && folder.pinHash!.isNotEmpty,
          bookmarkCount: row.read(bookmarkCount) ?? 0,
        );
      }).toList();
    });
  }

  Stream<List<Bookmark>> watchBookmarksInFolder(String folderId) {
    return (select(bookmarks)
          ..where((t) => t.folderId.equals(folderId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Future<Folder?> getFolderById(String id) {
    return (select(folders)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<Bookmark?> getBookmarkById(String id) {
    return (select(bookmarks)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<Folder> insertFolder({
    required String name,
    required int colorValue,
    required String iconName,
    bool isLocked = false,
    String? pinSalt,
    String? pinHash,
  }) async {
    final id = const Uuid().v4();
    final companion = FoldersCompanion.insert(
      id: id,
      name: name.trim(),
      isSystem: const Value(false),
      colorValue: Value(colorValue),
      iconName: Value(iconName),
      isLocked: Value(isLocked),
      pinSalt: Value(pinSalt),
      pinHash: Value(pinHash),
      createdAt: DateTime.now(),
    );
    await into(folders).insert(companion);
    return (select(folders)..where((t) => t.id.equals(id))).getSingle();
  }

  Future<void> updateFolder({
    required String id,
    String? name,
    int? colorValue,
    String? iconName,
    bool? isLocked,
    String? pinSalt,
    String? pinHash,
    bool clearPin = false,
  }) async {
    await (update(folders)..where((t) => t.id.equals(id))).write(
      FoldersCompanion(
        name: name == null ? const Value.absent() : Value(name.trim()),
        colorValue:
            colorValue == null ? const Value.absent() : Value(colorValue),
        iconName: iconName == null ? const Value.absent() : Value(iconName),
        isLocked: isLocked == null ? const Value.absent() : Value(isLocked),
        pinSalt: clearPin
            ? const Value(null)
            : pinSalt == null
                ? const Value.absent()
                : Value(pinSalt),
        pinHash: clearPin
            ? const Value(null)
            : pinHash == null
                ? const Value.absent()
                : Value(pinHash),
      ),
    );
  }

  Future<void> deleteFolder(String id) async {
    await (delete(folders)..where((t) => t.id.equals(id))).go();
  }

  Future<void> moveBookmarksToFolder(
    String fromFolderId,
    String toFolderId,
  ) async {
    await (update(bookmarks)..where((t) => t.folderId.equals(fromFolderId)))
        .write(BookmarksCompanion(folderId: Value(toFolderId)));
  }

  Future<Bookmark> insertBookmark({
    required String folderId,
    required String url,
    required String title,
    required FetchStatus fetchStatus,
  }) async {
    final id = const Uuid().v4();
    final companion = BookmarksCompanion.insert(
      id: id,
      folderId: folderId,
      url: url,
      title: title,
      fetchStatus: fetchStatus.storageValue,
      fetchedAt: const Value.absent(),
      createdAt: DateTime.now(),
    );
    await into(bookmarks).insert(companion);
    return (select(bookmarks)..where((t) => t.id.equals(id))).getSingle();
  }

  Future<void> updateBookmarkRow({
    required String id,
    String? url,
    String? title,
    String? folderId,
    FetchStatus? fetchStatus,
    DateTime? fetchedAt,
    bool clearFetchedAt = false,
  }) async {
    await (update(bookmarks)..where((t) => t.id.equals(id))).write(
      BookmarksCompanion(
        url: url == null ? const Value.absent() : Value(url),
        title: title == null ? const Value.absent() : Value(title),
        folderId: folderId == null ? const Value.absent() : Value(folderId),
        fetchStatus: fetchStatus == null
            ? const Value.absent()
            : Value(fetchStatus.storageValue),
        fetchedAt: clearFetchedAt
            ? const Value(null)
            : fetchedAt == null
                ? const Value.absent()
                : Value(fetchedAt),
      ),
    );
  }

  Future<void> deleteBookmark(String id) async {
    await (delete(bookmarks)..where((t) => t.id.equals(id))).go();
  }
}

class FolderWithCount {
  const FolderWithCount({
    required this.id,
    required this.name,
    required this.isSystem,
    required this.createdAt,
    required this.colorValue,
    required this.iconName,
    required this.isLocked,
    required this.hasPin,
    required this.bookmarkCount,
  });

  final String id;
  final String name;
  final bool isSystem;
  final DateTime createdAt;
  final int colorValue;
  final String iconName;
  final bool isLocked;
  final bool hasPin;
  final int bookmarkCount;
}
