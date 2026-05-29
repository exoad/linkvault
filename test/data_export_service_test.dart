import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkvault/data/app_database.dart';
import 'package:linkvault/services/data_export_service.dart';

void main() {
  test('buildPayload includes all tables', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.ensureUnfiled();

    final payload = await DataExportService(db).buildPayload();

    expect(payload['version'], DataExportService.exportVersion);
    expect(payload['exportedAt'], isNotEmpty);
    expect(payload['folders'], isA<List>());
    expect((payload['folders'] as List), isNotEmpty);
    expect(payload['bookmarks'], isA<List>());
    expect(payload['notes'], isA<List>());
    expect(payload['chatSessions'], isA<List>());
    expect(payload['chatMessages'], isA<List>());
  });
}
