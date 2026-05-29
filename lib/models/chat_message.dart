enum ChatMessageRole {
  user,
  assistant,
  tool;

  static ChatMessageRole fromStorage(String value) {
    return ChatMessageRole.values.firstWhere(
      (r) => r.name == value,
      orElse: () => ChatMessageRole.user,
    );
  }
}

class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    required this.createdAt,
    this.toolName,
  });

  final String id;
  final String sessionId;
  final ChatMessageRole role;
  final String content;
  final DateTime createdAt;
  final String? toolName;

  bool get isUser => role == ChatMessageRole.user;
}

class ChatSessionModel {
  const ChatSessionModel({
    required this.id,
    required this.title,
    required this.modelId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String modelId;
  final DateTime createdAt;
  final DateTime updatedAt;
}
