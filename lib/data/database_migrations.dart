import 'package:drift/drift.dart';

import 'app_database.dart';

/// Drift schema migrations for [AppDatabase].
///
/// **Policy:** upgrades are additive only (new columns/tables, data copies).
/// Never call [Migrator.drop], [Migrator.deleteTable], or recreate the DB here.
/// Destructive resets belong only in explicit user actions or dev-only tools.
abstract final class DatabaseMigrations {
  /// Runs migrations one version at a time: `from → from+1 → … → to`.
  static Future<void> migrateStepwise(
    Migrator migrator,
    int from,
    int to,
  ) async {
    if (from >= to) return;
    for (var version = from; version < to; version++) {
      await _migrate(migrator, version, version + 1);
    }
  }

  static Future<void> _migrate(Migrator m, int from, int to) async {
    if (to <= 1) return;

    switch (to) {
      case 2:
        await _toV2(m);
      default:
        throw StateError(
          'Missing migration to schema $to (from $from). '
          'Add a step in database_migrations.dart before shipping.',
        );
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
}
