import 'package:flutter_gemma/core/tool.dart';
import 'package:flutter_gemma/pigeon.g.dart';

import '../models/chat_model_definition.dart';

/// Abstraction for swappable on-device LLM backends (v1: [GemmaRuntime] only).
abstract class LocalLlmRuntime {
  ChatModelDefinition get model;

  Future<bool> isModelInstalled();

  Future<void> installModel({
    String? huggingFaceToken,
    void Function(int progress)? onProgress,
  });

  Future<void> uninstallModel();

  Future<void> ensureReady({
    required PreferredBackend preferredBackend,
    List<Tool> tools = const [],
  });

  PreferredBackend? get activeBackend;

  Future<void> replayHistory(List<LlmHistoryMessage> messages);

  Stream<LlmStreamEvent> sendUserMessage(String text);

  Future<void> stopGeneration();

  Future<void> dispose();
}

/// Role-aligned message for replay into native chat history.
class LlmHistoryMessage {
  const LlmHistoryMessage({
    required this.role,
    required this.content,
    this.toolName,
  });

  final LlmHistoryRole role;
  final String content;
  final String? toolName;
}

enum LlmHistoryRole { user, assistant, tool }

sealed class LlmStreamEvent {
  const LlmStreamEvent();
}

class LlmTokenEvent extends LlmStreamEvent {
  const LlmTokenEvent(this.token);
  final String token;
}

class LlmToolCallEvent extends LlmStreamEvent {
  const LlmToolCallEvent({required this.name, required this.argsSummary});
  final String name;
  final String argsSummary;
}

class LlmDoneEvent extends LlmStreamEvent {
  const LlmDoneEvent(this.fullText);
  final String fullText;
}

class LlmErrorEvent extends LlmStreamEvent {
  const LlmErrorEvent(this.message);
  final String message;
}
