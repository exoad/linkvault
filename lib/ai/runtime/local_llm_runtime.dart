import '../../platform/app_api.g.dart' as pigeon;
import '../models/chat_model_definition.dart';
import 'inference_backend.dart';

/// Context fill reported by native runtime or estimated in Dart.
typedef LlmContextUsage = ({int usedTokens, int maxTokens});

/// Swappable on-device LLM backend (v1: [NativeLlmRuntime] on Android).
abstract class LocalLlmRuntime {
  ChatModelDefinition get model;

  Future<bool> isModelInstalled();

  Future<void> installModel({
    String? huggingFaceToken,
    void Function(int progress)? onProgress,
  });

  Future<void> uninstallModel();

  Future<void> ensureReady({
    required InferenceBackend backend,
    pigeon.LlmGenerationConfig? generationConfig,
  });

  Future<void> applyGenerationConfig(pigeon.LlmGenerationConfig config);

  Future<LlmContextUsage?> readContextStats();

  InferenceBackend? get activeBackend;

  Future<void> resetChat();

  Future<void> replayHistory(List<LlmHistoryMessage> messages);

  Stream<LlmStreamEvent> sendUserMessage(String text);

  Stream<LlmStreamEvent> sendUserMessageWithToolHandler({
    required String text,
    required Future<String> Function(String name, Map<String, dynamic> args)
        onToolCall,
    int maxToolRounds,
  });

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

class LlmThinkingTokenEvent extends LlmStreamEvent {
  const LlmThinkingTokenEvent(this.token);
  final String token;
}

class LlmThinkingDoneEvent extends LlmStreamEvent {
  const LlmThinkingDoneEvent(this.fullText);
  final String fullText;
}

class LlmToolCallEvent extends LlmStreamEvent {
  const LlmToolCallEvent({
    required this.name,
    required this.args,
    required this.argsSummary,
  });
  final String name;
  final Map<String, dynamic> args;
  final String argsSummary;
}

class LlmToolResultEvent extends LlmStreamEvent {
  const LlmToolResultEvent({required this.name, required this.result});
  final String name;
  final String result;
}

class LlmDoneEvent extends LlmStreamEvent {
  const LlmDoneEvent(this.fullText);
  final String fullText;
}

class LlmErrorEvent extends LlmStreamEvent {
  const LlmErrorEvent(this.message);
  final String message;
}
