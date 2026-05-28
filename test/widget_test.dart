import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkvault/data/app_database.dart';
import 'package:linkvault/data/bookmark_repository.dart';
import 'package:linkvault/models/folder.dart';

// Drift watch streams + TestWidgetsFlutterBinding can leave pending timers;
// UI launch is covered indirectly via repository tests. This file keeps a
// fast smoke check for the data layer used on first paint.
void main() {
  test('bootstrap exposes Unfiled folder for home screen', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await database.ensureUnfiled();
    final repository = BookmarkRepository(database: database);

    final folders = await repository.watchFolders().first;
    expect(folders.any((f) => f.name == FolderModel.unfiledName), isTrue);
    expect(folders.firstWhere((f) => f.isSystem).iconName, isNotEmpty);
  });
}
