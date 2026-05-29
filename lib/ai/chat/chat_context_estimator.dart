import '../../models/chat_message.dart';
import 'tool_message_payload.dart';

/// Estimates token usage from Drift messages (fallback when native stats unavailable).
abstract final class ChatContextEstimator {
  static const charsPerToken = 4;

  static int estimateTokens(Iterable<ChatMessageModel> messages) {
    var chars = 0;
    for (final m in messages) {
      if (m.role == ChatMessageRole.thinking) continue;
      chars += m.content.length + 24;
      if (m.toolName != null) chars += m.toolName!.length;
    }
    return (chars / charsPerToken).ceil().clamp(1, 1 << 20);
  }

  static int estimateFromText(String text) =>
      (text.length / charsPerToken).ceil().clamp(1, 1 << 20);

  static String previewForRole(ChatMessageRole role) => switch (role) {
        ChatMessageRole.user => 'User',
        ChatMessageRole.assistant => 'Assistant',
        ChatMessageRole.tool => 'Tool',
        ChatMessageRole.thinking => 'Think',
      };

  static String summarizeLine(ChatMessageModel m) {
    var body = m.content;
    if (m.isTool) {
      body = ToolMessagePayload.parse(m.content).argsSummary;
    }
    if (body.length > 140) {
      body = '${body.substring(0, 140)}…';
    }
    return '${previewForRole(m.role)}: $body';
  }
}
