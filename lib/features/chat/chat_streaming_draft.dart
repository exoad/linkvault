import '../../models/chat_message.dart';
import '../../ai/chat/tool_message_payload.dart';

/// In-flight assistant turn shown before Drift catches up.
final class ChatStreamingDraft {
  ChatStreamingDraft({required this.sessionId});

  final String sessionId;
  String thinkingText = '';
  bool thinkingExpanded = true;
  final List<PendingToolCall> tools = [];
  String assistantText = '';

  void appendThinking(String chunk) => thinkingText += chunk;

  void appendAssistant(String chunk) => assistantText += chunk;

  PendingToolCall addToolCall({
    required String name,
    required String label,
    required String argsSummary,
    required Map<String, dynamic> args,
  }) {
    final call = PendingToolCall(
      id: 'pending-tool-${tools.length}',
      name: name,
      label: label,
      argsSummary: argsSummary,
      args: args,
    );
    tools.add(call);
    return call;
  }

  List<ChatMessageModel> buildMessages({required bool includeEmptyAssistant}) {
    final now = DateTime.now();
    final items = <ChatMessageModel>[];

    if (thinkingText.isNotEmpty) {
      items.add(
        ChatMessageModel(
          id: 'pending-thinking',
          sessionId: sessionId,
          role: ChatMessageRole.thinking,
          content: thinkingText,
          createdAt: now,
        ),
      );
    }

    for (final tool in tools) {
      items.add(
        ChatMessageModel(
          id: tool.id,
          sessionId: sessionId,
          role: ChatMessageRole.tool,
          content: tool.encodedContent,
          toolName: tool.name,
          createdAt: now,
        ),
      );
    }

    if (includeEmptyAssistant ||
        assistantText.isNotEmpty ||
        (tools.isEmpty && thinkingText.isEmpty)) {
      if (assistantText.isNotEmpty || includeEmptyAssistant) {
        items.add(
          ChatMessageModel(
            id: 'pending-assistant',
            sessionId: sessionId,
            role: ChatMessageRole.assistant,
            content: assistantText,
            createdAt: now,
          ),
        );
      }
    }

    return items;
  }

  PendingToolCall? toolById(String id) {
    for (final t in tools) {
      if (t.id == id) return t;
    }
    return null;
  }
}

final class PendingToolCall {
  PendingToolCall({
    required this.id,
    required this.name,
    required this.label,
    required this.argsSummary,
    required this.args,
  });

  final String id;
  final String name;
  final String label;
  final String argsSummary;
  final Map<String, dynamic> args;
  String? result;
  bool running = true;

  String get encodedContent =>
      ToolMessagePayload.encode(argsSummary: argsSummary, result: result);
}
