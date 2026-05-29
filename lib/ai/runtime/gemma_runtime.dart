import 'package:flutter_gemma/flutter_gemma.dart';

import '../models/chat_model_definition.dart';
import '../models/chat_model_registry.dart';
import 'local_llm_runtime.dart';

/// [LocalLlmRuntime] backed by [flutter_gemma].
final class GemmaRuntime implements LocalLlmRuntime {
  GemmaRuntime({ChatModelDefinition? model})
      : _model = model ?? ChatModelRegistry.defaultModel;

  final ChatModelDefinition _model;

  InferenceModel? _inferenceModel;
  InferenceChat? _chat;
  PreferredBackend? _requestedBackend;
  List<Tool> _tools = const [];
  static const _generationMaxTokens = 512;

  @override
  ChatModelDefinition get model => _model;

  @override
  PreferredBackend? get activeBackend => _requestedBackend;

  @override
  Future<bool> isModelInstalled() =>
      FlutterGemma.isModelInstalled(_model.modelFileName);

  @override
  Future<void> installModel({
    String? huggingFaceToken,
    void Function(int progress)? onProgress,
  }) async {
    var builder = FlutterGemma.installModel(
      modelType: _model.modelType,
      fileType: _model.modelFileType,
    ).fromNetwork(
      _model.installUrl,
      token: huggingFaceToken,
      foreground: true,
    );

    if (onProgress != null) {
      builder = builder.withProgress(onProgress);
    }

    await builder.install();
  }

  @override
  Future<void> uninstallModel() async {
    await dispose();
    await FlutterGemma.uninstallModel(_model.modelFileName);
  }

  @override
  Future<void> ensureReady({
    required PreferredBackend preferredBackend,
    List<Tool> tools = const [],
  }) async {
    _requestedBackend = preferredBackend;
    _tools = tools;

    _inferenceModel = await FlutterGemma.getActiveModel(
      maxTokens: _generationMaxTokens,
      preferredBackend: preferredBackend,
    );

    await _recreateChat();
  }

  /// Clears native conversation state (e.g. when switching Drift sessions).
  Future<void> resetChat() => _recreateChat();

  Future<void> _recreateChat() async {
    final inference = _inferenceModel;
    if (inference == null) {
      throw StateError('Model not loaded');
    }

    await _chat?.session.close();
    _chat = await inference.createChat(
      temperature: 1.0,
      randomSeed: 1,
      topK: 64,
      topP: 0.95,
      tokenBuffer: 256,
      supportsFunctionCalls: _model.supportsFunctionCalls,
      tools: _tools,
      modelType: _model.modelType,
    );
  }

  @override
  Future<void> replayHistory(List<LlmHistoryMessage> messages) async {
    final chat = _chat;
    if (chat == null) {
      throw StateError('Chat not initialized');
    }

    for (final entry in messages) {
      final message = _toGemmaMessage(entry);
      await chat.addQueryChunk(message, true);
    }
  }

  Message _toGemmaMessage(LlmHistoryMessage entry) {
    return switch (entry.role) {
      LlmHistoryRole.user => Message.text(text: entry.content, isUser: true),
      LlmHistoryRole.assistant =>
        Message.text(text: entry.content, isUser: false),
      LlmHistoryRole.tool => Message.toolResponse(
          toolName: entry.toolName ?? 'tool',
          response: {'result': entry.content},
        ),
    };
  }

  @override
  Stream<LlmStreamEvent> sendUserMessage(String text) {
    return sendUserMessageWithToolHandler(
      text: text,
      onToolCall: (_, _) async => 'Tool execution not configured.',
    );
  }

  /// Send user text with tool execution delegated to [onToolCall].
  Stream<LlmStreamEvent> sendUserMessageWithToolHandler({
    required String text,
    required Future<String> Function(String name, Map<String, dynamic> args)
        onToolCall,
    int maxToolRounds = 3,
  }) async* {
    final chat = _chat;
    if (chat == null) {
      yield const LlmErrorEvent('Model is not ready.');
      return;
    }

    await chat.addQuery(Message.text(text: text, isUser: true));

    var toolRounds = 0;
    while (true) {
      final buffer = StringBuffer();
      FunctionCallResponse? pendingCall;

      await for (final response in chat.generateChatResponseAsync()) {
        switch (response) {
          case TextResponse(:final token):
            if (token.isEmpty) continue;
            buffer.write(token);
            yield LlmTokenEvent(token);
          case FunctionCallResponse call:
            pendingCall = call;
          case ThinkingResponse():
            break;
        }
        if (pendingCall != null) break;
      }

      if (pendingCall == null) {
        yield LlmDoneEvent(buffer.toString());
        return;
      }

      toolRounds++;
      if (toolRounds > maxToolRounds) {
        yield const LlmErrorEvent('Too many tool calls for one message.');
        return;
      }

      final call = pendingCall;
      final summary =
          call.args.entries.map((e) => '${e.key}: ${e.value}').join(', ');
      yield LlmToolCallEvent(name: call.name, argsSummary: summary);

      final result = await onToolCall(call.name, call.args);
      await chat.addQuery(
        Message.toolResponse(
          toolName: call.name,
          response: {'result': result},
        ),
      );
    }
  }

  @override
  Future<void> stopGeneration() async {
    await _chat?.stopGeneration();
  }

  @override
  Future<void> dispose() async {
    await _chat?.session.close();
    _chat = null;
    await _inferenceModel?.close();
    _inferenceModel = null;
  }
}
