import 'package:drift/drift.dart';

import 'app_database.dart';

/// Drift schema migrations for [AppDatabase].
///
/// **Policy:** upgrades are additive only (new columns/tables, data copies).
/// Never call [Migrator.drop], [Migrator.deleteTable], or recreate the DB here.
///
/// **Automatic upgrades:** [AppDatabase] calls [migrateStepwise] from
/// `MigrationStrategy.onUpgrade` whenever an installed DB has
/// `user_version < schemaVersion`. Users do not need to take any action.
abstract final class DatabaseMigrations {
  /// Keep in sync with [AppDatabase.schemaVersion].
  static const int targetSchemaVersion = 4;

  /// Target versions that have a registered upgrade step (2 … [targetSchemaVersion]).
  static final Map<int, Future<void> Function(Migrator migrator)> steps = {
    2: _toV2,
    3: _toV3,
    4: _toV4,
  };

  static bool hasStepForVersion(int version) => steps.containsKey(version);

  /// Runs migrations one version at a time: `from → from+1 → … → to`.
  static Future<void> migrateStepwise(
    Migrator migrator,
    int from,
    int to,
  ) async {
    if (from >= to) return;

    for (var version = from + 1; version <= to; version++) {
      final step = steps[version];
      if (step == null) {
        throw StateError(
          'Missing migration to schema $version (from $from, target $to). '
          'Register steps[$version] in database_migrations.dart and bump '
          'AppDatabase.schemaVersion before shipping.',
        );
      }
      await step(migrator);
    }
  }

  /// v1 → v2: folder appearance + PIN columns (existing rows kept).
  static Future<void> _toV2(Migrator m) async {
    final db = m.database as AppDatabase;
    await m.addColumn(db.folders, db.folders.colorValue);
    await m.addColumn(db.folders, db.folders.iconName);
    await m.addColumn(db.folders, db.folders.isLocked);
    await m.addColumn(db.folders, db.folders.pinSalt);
    await m.addColumn(db.folders, db.folders.pinHash);
  }

  /// v2 → v3: notes app storage.
  static Future<void> _toV3(Migrator m) async {
    await m.createTable((m.database as AppDatabase).notes);
  }

  /// v3 → v4: local AI chat history.
  static Future<void> _toV4(Migrator m) async {
    final db = m.database as AppDatabase;
    await m.createTable(db.chatSessions);
    await m.createTable(db.chatMessages);
  }
}
