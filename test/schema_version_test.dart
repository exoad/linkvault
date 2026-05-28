import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkvault/data/app_database.dart';
import 'package:linkvault/data/database_migrations.dart';

void main() {
  test('AppDatabase.schemaVersion matches migration target', () {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    expect(db.schemaVersion, DatabaseMigrations.targetSchemaVersion);
    db.close();
  });

  test('every schema version has a migration step', () {
    for (var v = 2; v <= DatabaseMigrations.targetSchemaVersion; v++) {
      expect(
        DatabaseMigrations.hasStepForVersion(v),
        isTrue,
        reason: 'Add DatabaseMigrations.steps[$v] before release',
      );
    }
  });
}
