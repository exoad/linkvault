import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/fetch_status.dart';
import '../models/folder.dart';
import 'database_migrations.dart';

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

class Notes extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get body => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class ChatSessions extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withDefault(const Constant('New chat'))();
  TextColumn get modelId => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class ChatMessages extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text().references(ChatSessions, #id)();
  TextColumn get role => text()();
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get toolName => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Folders, Bookmarks, Notes, ChatSessions, ChatMessages])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  AppDatabase.forTesting(super.executor);

  /// Bumped when adding tables/columns; [DatabaseMigrations] upgrades on open.
  @override
  int get schemaVersion => DatabaseMigrations.targetSchemaVersion;

  static const _unfiledId = 'system-unfiled';

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _seedUnfiled();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Automatic stepwise migration (e.g. v2 → v3 adds `notes`).
          await DatabaseMigrations.migrateStepwise(m, from, to);
          await _seedUnfiled();
        },
        beforeOpen: (details) async {
          if (details.hadUpgrade) {
            await _seedUnfiled();
          }
        },
      );

  /// Stable on-disk name so APK updates reuse the same SQLite file.
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

  Stream<List<Note>> watchNotes() {
    return (select(notes)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  Stream<int> watchNoteCount() {
    final count = notes.id.count();
    final query = selectOnly(notes)..addColumns([count]);
    return query.watch().map((rows) {
      if (rows.isEmpty) return 0;
      return rows.first.read(count) ?? 0;
    });
  }

  Future<Note?> getNoteById(String id) {
    return (select(notes)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<Note> insertNote({
    required String title,
    required String body,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    await into(notes).insert(
      NotesCompanion.insert(
        id: id,
        title: Value(title.trim()),
        body: Value(body),
        createdAt: now,
        updatedAt: now,
      ),
    );
    return (select(notes)..where((t) => t.id.equals(id))).getSingle();
  }

  Future<void> updateNoteRow({
    required String id,
    String? title,
    String? body,
  }) async {
    await (update(notes)..where((t) => t.id.equals(id))).write(
      NotesCompanion(
        title: title == null ? const Value.absent() : Value(title.trim()),
        body: body == null ? const Value.absent() : Value(body),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteNote(String id) async {
    await (delete(notes)..where((t) => t.id.equals(id))).go();
  }

  Stream<List<ChatSession>> watchChatSessions() {
    return (select(chatSessions)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  Stream<List<ChatMessage>> watchChatMessages(String sessionId) {
    return (select(chatMessages)
          ..where((t) => t.sessionId.equals(sessionId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  Future<List<ChatMessage>> getChatMessages(String sessionId) {
    return (select(chatMessages)
          ..where((t) => t.sessionId.equals(sessionId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<ChatSession?> getChatSessionById(String id) {
    return (select(chatSessions)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<ChatSession> insertChatSession({
    required String modelId,
    String title = 'New chat',
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    await into(chatSessions).insert(
      ChatSessionsCompanion.insert(
        id: id,
        title: Value(title),
        modelId: modelId,
        createdAt: now,
        updatedAt: now,
      ),
    );
    return (select(chatSessions)..where((t) => t.id.equals(id))).getSingle();
  }

  Future<void> updateChatSession({
    required String id,
    String? title,
    DateTime? updatedAt,
  }) async {
    await (update(chatSessions)..where((t) => t.id.equals(id))).write(
      ChatSessionsCompanion(
        title: title == null ? const Value.absent() : Value(title),
        updatedAt: updatedAt == null
            ? const Value.absent()
            : Value(updatedAt),
      ),
    );
  }

  Future<void> deleteChatSession(String id) async {
    await (delete(chatMessages)..where((t) => t.sessionId.equals(id))).go();
    await (delete(chatSessions)..where((t) => t.id.equals(id))).go();
  }

  Future<ChatMessage> insertChatMessage({
    required String sessionId,
    required String role,
    required String content,
    String? toolName,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    await into(chatMessages).insert(
      ChatMessagesCompanion.insert(
        id: id,
        sessionId: sessionId,
        role: role,
        content: content,
        createdAt: now,
        toolName: toolName == null ? const Value.absent() : Value(toolName),
      ),
    );
    return (select(chatMessages)..where((t) => t.id.equals(id))).getSingle();
  }

  Future<void> deleteChatMessagesInSession(String sessionId) async {
    await (delete(chatMessages)..where((t) => t.sessionId.equals(sessionId)))
        .go();
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
