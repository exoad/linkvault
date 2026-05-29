import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkvault/data/app_database.dart';
import 'package:linkvault/data/chat_repository.dart';
import 'package:linkvault/models/chat_message.dart';

void main() {
  test('create session, messages, and watch', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final repo = ChatRepository(database: db);

    final sessionId = await repo.createSession(modelId: 'gemma-4-e2b');
    await repo.insertMessage(
      sessionId: sessionId,
      role: ChatMessageRole.user,
      content: 'Hello',
    );
    await repo.insertMessage(
      sessionId: sessionId,
      role: ChatMessageRole.assistant,
      content: 'Hi there',
    );

    final messages = await repo.watchMessages(sessionId).first;
    expect(messages, hasLength(2));
    expect(messages.first.content, 'Hello');
    expect(messages.last.content, 'Hi there');

    final sessions = await repo.watchSessions().first;
    expect(sessions, hasLength(1));
    expect(sessions.first.id, sessionId);

    await repo.deleteSession(sessionId);
    final afterDelete = await repo.watchSessions().first;
    expect(afterDelete, isEmpty);

    await db.close();
  });
}
