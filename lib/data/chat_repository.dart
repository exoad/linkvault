import '../models/chat_message.dart';
import 'app_database.dart';

class ChatRepository {
  ChatRepository({required AppDatabase database}) : _db = database;

  final AppDatabase _db;

  Stream<List<ChatSessionModel>> watchSessions() {
    return _db.watchChatSessions().map((rows) => rows.map(_sessionToModel).toList());
  }

  Stream<List<ChatMessageModel>> watchMessages(String sessionId) {
    return _db
        .watchChatMessages(sessionId)
        .map((rows) => rows.map(_messageToModel).toList());
  }

  Future<List<ChatMessageModel>> getMessages(String sessionId) async {
    final rows = await _db.getChatMessages(sessionId);
    return rows.map(_messageToModel).toList();
  }

  Future<String> createSession({
    required String modelId,
    String title = 'New chat',
  }) async {
    final row = await _db.insertChatSession(modelId: modelId, title: title);
    return row.id;
  }

  Future<void> insertMessage({
    required String sessionId,
    required ChatMessageRole role,
    required String content,
    String? toolName,
  }) async {
    await _db.insertChatMessage(
      sessionId: sessionId,
      role: role.name,
      content: content,
      toolName: toolName,
    );
    await touchSession(sessionId);
  }

  Future<void> touchSession(String sessionId, {String? preview}) async {
    final session = await _db.getChatSessionById(sessionId);
    if (session == null) return;

    var title = session.title;
    if (title == 'New chat' && preview != null && preview.isNotEmpty) {
      final shortened = preview.length > 48 ? '${preview.substring(0, 48)}…' : preview;
      title = shortened;
    }

    await _db.updateChatSession(
      id: sessionId,
      title: title,
      updatedAt: DateTime.now(),
    );
  }

  Future<void> deleteSession(String sessionId) => _db.deleteChatSession(sessionId);

  Future<void> deleteMessagesInSession(String sessionId) =>
      _db.deleteChatMessagesInSession(sessionId);

  ChatSessionModel _sessionToModel(ChatSession row) {
    return ChatSessionModel(
      id: row.id,
      title: row.title,
      modelId: row.modelId,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  ChatMessageModel _messageToModel(ChatMessage row) {
    return ChatMessageModel(
      id: row.id,
      sessionId: row.sessionId,
      role: ChatMessageRole.fromStorage(row.role),
      content: row.content,
      createdAt: row.createdAt,
      toolName: row.toolName,
    );
  }
}
