import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkvault/data/app_database.dart';
import 'package:linkvault/data/note_repository.dart';

void main() {
  test('create, update, delete note', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final repo = NoteRepository(database: db);

    final created = await repo.createNote(
      const NoteUpsert(title: 'Groceries', body: 'Milk\nEggs'),
    );
    expect(created.displayTitle, 'Groceries');
    expect(created.preview, contains('Milk'));

    await repo.updateNote(
      created.id,
      const NoteUpsert(title: 'Shopping', body: 'Bread'),
    );

    final updated = await repo.getNote(created.id);
    expect(updated!.title, 'Shopping');
    expect(updated.body, 'Bread');

    await repo.deleteNote(created.id);
    final notes = await repo.watchNotes().first;
    expect(notes, isEmpty);

    await db.close();
  });
}
