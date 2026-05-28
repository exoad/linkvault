import '../models/note.dart';
import 'app_database.dart';

class NoteUpsert {
  const NoteUpsert({required this.title, required this.body});

  final String title;
  final String body;
}

class NoteRepository {
  NoteRepository({required AppDatabase database}) : _db = database;

  final AppDatabase _db;

  Stream<List<NoteModel>> watchNotes() {
    return _db.watchNotes().map((rows) => rows.map(_toModel).toList());
  }

  Stream<int> watchNoteCount() => _db.watchNoteCount();

  Future<NoteModel?> getNote(String id) async {
    final row = await _db.getNoteById(id);
    return row == null ? null : _toModel(row);
  }

  Future<NoteModel> createNote(NoteUpsert upsert) async {
    final row = await _db.insertNote(
      title: upsert.title,
      body: upsert.body,
    );
    return _toModel(row);
  }

  Future<void> updateNote(String id, NoteUpsert upsert) async {
    await _db.updateNoteRow(
      id: id,
      title: upsert.title,
      body: upsert.body,
    );
  }

  Future<void> deleteNote(String id) => _db.deleteNote(id);

  NoteModel _toModel(Note row) {
    return NoteModel(
      id: row.id,
      title: row.title,
      body: row.body,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
