import 'package:flutter_gemma/pigeon.g.dart';

import '../../data/chat_repository.dart';
import '../../models/chat_message.dart';
import '../models/chat_model_registry.dart';
import '../runtime/gemma_runtime.dart';
import '../runtime/inference_backend.dart';
import '../runtime/local_llm_runtime.dart';
import '../tools/tool_registry.dart';
import 'chat_hf_token_preferences.dart';

export '../runtime/local_llm_runtime.dart' show LlmStreamEvent, LlmTokenEvent;

/// Orchestrates model install, Drift history, and tool-augmented generation.
final class ChatService {
  ChatService({
    required this.repository,
    required this.runtime,
    required ToolRegistry toolRegistry,
    required this.backendPrefs,
    required this.hfTokenPrefs,
  }) : _tools = toolRegistry;

  final ChatRepository repository;
  final GemmaRuntime runtime;
  final ToolRegistry _tools;
  final InferenceBackendPreferences backendPrefs;
  final ChatHfTokenPreferences hfTokenPrefs;

  PreferredBackend? get activeBackend => runtime.activeBackend;

  String get backendStatusLabel {
    final backend = runtime.activeBackend;
    if (backend == null) return '';
    return backend == PreferredBackend.gpu ? 'Using GPU' : 'Using CPU';
  }

  Future<bool> isModelInstalled() => runtime.isModelInstalled();

  Future<void> installModel({void Function(int progress)? onProgress}) {
    return runtime.installModel(
      huggingFaceToken: hfTokenPrefs.token,
      onProgress: onProgress,
    );
  }

  Future<void> uninstallModel() => runtime.uninstallModel();

  Future<void> ensureModelReady() async {
    final backend = backendPrefs.backend.toPreferredBackend();
    await runtime.ensureReady(
      preferredBackend: backend,
      tools: _tools.gemmaTools,
    );
  }

  Future<String> createSession({String? title}) {
    return repository.createSession(
      modelId: ChatModelRegistry.defaultModel.id,
      title: title ?? 'New chat',
    );
  }

  Future<void> prepareSession(String sessionId) async {
    await ensureModelReady();
    await runtime.resetChat();
    final rows = await repository.getMessages(sessionId);
    final history = rows
        .where((m) => m.role != ChatMessageRole.tool || m.toolName != null)
        .map(
          (m) => LlmHistoryMessage(
            role: switch (m.role) {
              ChatMessageRole.user => LlmHistoryRole.user,
              ChatMessageRole.assistant => LlmHistoryRole.assistant,
              ChatMessageRole.tool => LlmHistoryRole.tool,
            },
            content: m.content,
            toolName: m.toolName,
          ),
        )
        .toList();
    await runtime.replayHistory(history);
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

    final stream = runtime.sendUserMessageWithToolHandler(
      text: trimmed,
      onToolCall: (name, args) => _tools.execute(name, args),
    );

    final assistantBuffer = StringBuffer();
    await for (final event in stream) {
      switch (event) {
        case LlmTokenEvent(:final token):
          assistantBuffer.write(token);
          yield event;
        case LlmToolCallEvent(:final name, :final argsSummary):
          await repository.insertMessage(
            sessionId: sessionId,
            role: ChatMessageRole.tool,
            content: argsSummary,
            toolName: name,
          );
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
        case LlmErrorEvent():
          yield event;
      }
    }
  }

  Future<void> stopGeneration() => runtime.stopGeneration();

  Future<void> clearSessionMessages(String sessionId) async {
    await repository.deleteMessagesInSession(sessionId);
    await runtime.dispose();
  }
}
