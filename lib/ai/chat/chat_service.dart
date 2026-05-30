import '../../data/chat_repository.dart';
import '../../models/chat_message.dart';
import '../models/chat_model_registry.dart';
import '../runtime/inference_backend.dart';
import '../runtime/local_llm_runtime.dart';
import '../runtime/native_llm_runtime.dart';
import '../tools/tool_registry.dart';
import 'chat_compressor.dart';
import 'chat_context_estimator.dart';
import 'chat_hf_token_preferences.dart';
import 'chat_inference_preferences.dart';
import 'chat_session_preferences.dart';
import 'tool_message_payload.dart';

export '../runtime/local_llm_runtime.dart' show LlmStreamEvent, LlmTokenEvent;

/// Steps reported while [ChatService.prepareSession] runs.
enum ChatPrepareStep {
  loadingModel,
  resetting,
  replayingHistory,
  done,
}

/// Orchestrates native Kotlin inference, Drift history, and tools.
final class ChatService {
  ChatService({
    required this.repository,
    required this.runtime,
    required ToolRegistry toolRegistry,
    required this.backendPrefs,
    required this.hfTokenPrefs,
    required this.inferencePrefs,
    required this.sessionPrefs,
  }) : _tools = toolRegistry,
       _compressor = ChatCompressor(repository: repository);

  factory ChatService.android({
    required ChatRepository repository,
    required ToolRegistry toolRegistry,
    required InferenceBackendPreferences backendPrefs,
    required ChatHfTokenPreferences hfTokenPrefs,
    required ChatInferencePreferences inferencePrefs,
    required ChatSessionPreferences sessionPrefs,
  }) {
    return ChatService(
      repository: repository,
      runtime: NativeLlmRuntime(),
      toolRegistry: toolRegistry,
      backendPrefs: backendPrefs,
      hfTokenPrefs: hfTokenPrefs,
      inferencePrefs: inferencePrefs,
      sessionPrefs: sessionPrefs,
    );
  }

  final ChatRepository repository;
  final LocalLlmRuntime runtime;
  final ToolRegistry _tools;
  final ChatCompressor _compressor;
  final InferenceBackendPreferences backendPrefs;
  final ChatHfTokenPreferences hfTokenPrefs;
  final ChatInferencePreferences inferencePrefs;
  final ChatSessionPreferences sessionPrefs;

  InferenceBackend? get activeBackend => runtime.activeBackend;

  String get backendStatusLabel {
    final backend = runtime.activeBackend;
    if (backend == null) return '';
    return 'Using ${backend.label}';
  }

  String toolLabel(String name) => _tools.labelFor(name);

  Stream<List<ChatSessionModel>> watchSessions() => repository.watchSessions();

  Future<String?> get savedSessionId async => sessionPrefs.activeSessionId;

  Future<void> rememberSession(String sessionId) =>
      sessionPrefs.setActiveSessionId(sessionId);

  Future<bool> isModelInstalled() => runtime.isModelInstalled();

  Future<void> installModel({void Function(int progress)? onProgress}) {
    return runtime.installModel(
      huggingFaceToken: hfTokenPrefs.token,
      onProgress: onProgress,
    );
  }

  Future<void> uninstallModel() => runtime.uninstallModel();

  Future<void> ensureModelReady() async {
    final backend = backendPrefs.backend;
    try {
      await runtime.ensureReady(
        backend: backend,
        generationConfig: inferencePrefs.toPigeon(),
      );
    } catch (e) {
      if (backend != InferenceBackend.gpu) rethrow;
      await _fallbackToCpu();
    }
  }

  Future<void> applyInferenceSettings() async {
    await runtime.applyGenerationConfig(inferencePrefs.toPigeon());
  }

  Future<LlmContextUsage> contextUsageFor(String sessionId) async {
    final native = await runtime.readContextStats();
    if (native != null) {
      return native;
    }
    final used = ChatContextEstimator.estimateTokens(
      await repository.getMessages(sessionId),
    );
    return (
      usedTokens: used,
      maxTokens: inferencePrefs.contextTokenLimit,
    );
  }

  Future<String> createSession({String? title}) async {
    final id = await repository.createSession(
      modelId: ChatModelRegistry.defaultModel.id,
      title: title ?? 'New chat',
    );
    await rememberSession(id);
    return id;
  }

  Future<void> deleteSession(String sessionId) async {
    await repository.deleteSession(sessionId);
    if (sessionPrefs.activeSessionId == sessionId) {
      await sessionPrefs.setActiveSessionId(null);
    }
  }

  Future<void> prepareSession(
    String sessionId, {
    void Function(ChatPrepareStep step)? onProgress,
  }) async {
    onProgress?.call(ChatPrepareStep.loadingModel);
    await ensureModelReady();
    onProgress?.call(ChatPrepareStep.resetting);
    await runtime.resetChat();
    final rows = await repository.getMessages(sessionId);
    final history = rows
        .where(
          (m) =>
              m.role != ChatMessageRole.thinking &&
              (m.role != ChatMessageRole.tool || m.toolName != null),
        )
        .map(
          (m) => LlmHistoryMessage(
            role: switch (m.role) {
              ChatMessageRole.user => LlmHistoryRole.user,
              ChatMessageRole.assistant => LlmHistoryRole.assistant,
              ChatMessageRole.tool => LlmHistoryRole.tool,
              ChatMessageRole.thinking => LlmHistoryRole.assistant,
            },
            content: m.content,
            toolName: m.toolName,
          ),
        )
        .toList();
    onProgress?.call(ChatPrepareStep.replayingHistory);
    await runtime.replayHistory(history);
    await rememberSession(sessionId);
    onProgress?.call(ChatPrepareStep.done);
  }

  Future<int> compressSession(String sessionId, {int keepRecent = 8}) async {
    final removed = await _compressor.compressSession(
      sessionId,
      keepRecent: keepRecent,
    );
    if (removed > 0) {
      await prepareSession(sessionId);
    }
    return removed;
  }

  Stream<LlmStreamEvent> sendMessage({
    required String sessionId,
    required String text,
  }) async* {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    await repository.insertMessage(
      sessionId: sessionId,
      role: ChatMessageRole.user,
      content: trimmed,
    );

    await ensureModelReady();

    final stream = runtime.sendUserMessageWithToolHandler(
      text: trimmed,
      onToolCall: (name, args) => _tools.execute(name, args),
    );

    final assistantBuffer = StringBuffer();
    final thinkingBuffer = StringBuffer();
    String? openToolMessageId;
    String? openToolArgsSummary;

    await for (final event in stream) {
      switch (event) {
        case LlmThinkingTokenEvent(:final token):
          thinkingBuffer.write(token);
          yield event;
        case LlmThinkingDoneEvent(:final fullText):
          thinkingBuffer.write(fullText);
          final thinking = thinkingBuffer.toString().trim();
          if (thinking.isNotEmpty) {
            await repository.insertMessage(
              sessionId: sessionId,
              role: ChatMessageRole.thinking,
              content: thinking,
            );
            thinkingBuffer.clear();
          }
          yield event;
        case LlmTokenEvent(:final token):
          assistantBuffer.write(token);
          yield event;
        case LlmToolCallEvent(:final name, :final argsSummary):
          openToolArgsSummary = argsSummary;
          openToolMessageId = await repository.insertMessage(
            sessionId: sessionId,
            role: ChatMessageRole.tool,
            content: ToolMessagePayload.encode(argsSummary: argsSummary),
            toolName: name,
          );
          yield event;
        case LlmToolResultEvent(:final result):
          final toolId = openToolMessageId;
          final summary = openToolArgsSummary;
          if (toolId != null && summary != null) {
            await repository.updateMessageContent(
              messageId: toolId,
              content: ToolMessagePayload.encode(
                argsSummary: summary,
                result: result,
              ),
            );
          }
          openToolMessageId = null;
          openToolArgsSummary = null;
          yield event;
        case LlmDoneEvent(:final fullText):
          final content =
              fullText.isNotEmpty ? fullText : assistantBuffer.toString();
          if (content.isNotEmpty) {
            await repository.insertMessage(
              sessionId: sessionId,
              role: ChatMessageRole.assistant,
              content: content,
            );
            await repository.touchSession(sessionId, preview: trimmed);
          }
          yield LlmDoneEvent(content);
        case LlmErrorEvent(:final message):
          final updated = await _maybeFallbackToCpu(message);
          yield LlmErrorEvent(updated);
      }
    }
  }

  Future<void> stopGeneration() => runtime.stopGeneration();

  Future<void> clearSessionMessages(String sessionId) async {
    await repository.deleteMessagesInSession(sessionId);
    await runtime.dispose();
  }

  Future<void> _fallbackToCpu() async {
    await backendPrefs.setBackend(InferenceBackend.cpu);
    await runtime.ensureReady(
      backend: InferenceBackend.cpu,
      generationConfig: inferencePrefs.toPigeon(),
    );
  }

  Future<String> _maybeFallbackToCpu(String message) async {
    final backend = runtime.activeBackend ?? backendPrefs.backend;
    if (backend != InferenceBackend.gpu) return message;
    if (!_shouldFallback(message)) return message;
    try {
      await _fallbackToCpu();
      return 'GPU inference failed — switched to CPU';
    } catch (e) {
      return '$message (CPU fallback failed: $e)';
    }
  }

  bool _shouldFallback(String message) {
    final code = _errorCode(message);
    return code == 'GENERATION_FAILED' ||
        code == 'NOT_LOADED' ||
        code == 'NO_SESSION';
  }

  String _errorCode(String message) {
    final separator = message.indexOf(':');
    if (separator <= 0) return message.trim();
    return message.substring(0, separator).trim();
  }
}
