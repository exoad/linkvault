import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkvault/ai/chat/chat_compressor.dart';
import 'package:linkvault/data/app_database.dart';
import 'package:linkvault/data/chat_repository.dart';
import 'package:linkvault/models/chat_message.dart';

void main() {
  test('compressSession replaces old rows with summary', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final repo = ChatRepository(database: db);
    final compressor = ChatCompressor(repository: repo);

    final sessionId = await repo.createSession(modelId: 'gemma-4-e2b');
    for (var i = 0; i < 12; i++) {
      await repo.insertMessage(
        sessionId: sessionId,
        role: ChatMessageRole.user,
        content: 'Message $i',
      );
    }

    final removed = await compressor.compressSession(sessionId, keepRecent: 4);
    expect(removed, 8);

    final after = await repo.getMessages(sessionId);
    expect(after.length, lessThan(12));
    expect(
      after.any((m) => m.content.startsWith(ChatCompressor.summaryPrefix)),
      isTrue,
    );

    await db.close();
  });
}
