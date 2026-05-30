import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show visibleForTesting;

import '../../platform/app_api.g.dart' as pigeon;
import '../chat/flutter_llm_bridge.dart';
import '../models/chat_model_definition.dart';
import '../models/chat_model_registry.dart';
import 'inference_backend.dart';
import 'llm_host_gateway.dart';
import 'local_llm_runtime.dart';

/// On-device LLM via Kotlin (LiteRT-LM / MediaPipe). Inference stays off the Dart isolate.
final class NativeLlmRuntime implements LocalLlmRuntime {
  NativeLlmRuntime._({
    required ChatModelDefinition model,
    required LlmHostGateway host,
    required bool platformGuard,
    required bool installBridge,
  })  : _model = model,
        _host = host,
        _platformGuard = platformGuard,
        _installBridge = installBridge {
    if (_installBridge && _platformGuard && Platform.isAndroid) {
      FlutterLlmBridge.install();
    }
  }

  factory NativeLlmRuntime({
    ChatModelDefinition? model,
    LlmHostGateway? host,
  }) =>
      NativeLlmRuntime._(
        model: model ?? ChatModelRegistry.defaultModel,
        host: host ?? PigeonLlmHostGateway(),
        platformGuard: host == null,
        installBridge: true,
      );

  /// Test-only: no Android guard; supply a [LlmHostGateway] fake.
  @visibleForTesting
  NativeLlmRuntime.testing({
    required LlmHostGateway host,
    ChatModelDefinition? model,
  }) : this._(
          model: model ?? ChatModelRegistry.defaultModel,
          host: host,
          platformGuard: false,
          installBridge: false,
        );

  final ChatModelDefinition _model;
  final LlmHostGateway _host;
  final bool _platformGuard;
  final bool _installBridge;
  InferenceBackend? _loadedBackend;

  void _requireNative() {
    if (_platformGuard && !Platform.isAndroid) {
      throw UnsupportedError('Native LLM is Android-only');
    }
  }

  @override
  ChatModelDefinition get model => _model;

  @override
  InferenceBackend? get activeBackend => _loadedBackend;

  @override
  Future<bool> isModelInstalled() async {
    if (_platformGuard && !Platform.isAndroid) return false;
    return _host.isModelInstalled(_model.modelFileName);
  }

  @override
  Future<void> installModel({
    String? huggingFaceToken,
    void Function(int progress)? onProgress,
  }) async {
    _requireNative();
    final bridge = FlutterLlmBridge.instance;
    bridge.setDownloadListener(onProgress);
    final downloadDone = bridge.waitForDownloadComplete();
    await _host.startModelDownload(
      _model.installUrl,
      _model.modelFileName,
      huggingFaceToken,
    );
    await downloadDone.timeout(
      const Duration(hours: 6),
      onTimeout: () => throw TimeoutException('Model download timed out'),
    );
    bridge.setDownloadListener(null);
    if (!await isModelInstalled()) {
      throw StateError('Model download finished but file is missing');
    }
  }

  @override
  Future<void> uninstallModel() async {
    await dispose();
    if (!_platformGuard || Platform.isAndroid) {
      await _host.uninstallModel(_model.modelFileName);
    }
  }

  @override
  Future<void> ensureReady({
    required InferenceBackend backend,
    pigeon.LlmGenerationConfig? generationConfig,
  }) async {
    _requireNative();
    _loadedBackend = backend;
    final maxOut = generationConfig?.maxOutputTokens ?? _model.maxTokens;
    await _host
        .loadModel(
          _model.modelFileName,
          backend.toPigeon(),
          maxOut,
        )
        .timeout(
          const Duration(seconds: 120),
          onTimeout: () => throw TimeoutException(
            'Model load timed out after 2 minutes',
          ),
        );
    if (generationConfig != null) {
      await _host.applyGenerationConfig(generationConfig);
    }
  }

  @override
  Future<void> applyGenerationConfig(pigeon.LlmGenerationConfig config) async {
    _requireNative();
    await _host.applyGenerationConfig(config);
  }

  @override
  Future<LlmContextUsage?> readContextStats() async {
    if (_platformGuard && !Platform.isAndroid) return null;
    final stats = await _host.getContextStats();
    return (usedTokens: stats.usedTokens, maxTokens: stats.maxTokens);
  }

  @override
  Future<void> resetChat() => _host.resetConversation();

  @override
  Future<void> replayHistory(List<LlmHistoryMessage> messages) async {
    final pigeonMessages = messages
        .map(
          (m) => pigeon.LlmHistoryMessage(
            role: switch (m.role) {
              LlmHistoryRole.user => pigeon.LlmHistoryRole.user,
              LlmHistoryRole.assistant => pigeon.LlmHistoryRole.assistant,
              LlmHistoryRole.tool => pigeon.LlmHistoryRole.tool,
            },
            content: m.content,
            toolName: m.toolName,
          ),
        )
        .toList();
    await _host.replayHistory(pigeonMessages);
  }

  @override
  Stream<LlmStreamEvent> sendUserMessage(String text) {
    return sendUserMessageWithToolHandler(
      text: text,
      onToolCall: (_, _) async => 'Tool execution not configured.',
      maxToolRounds: 0,
    );
  }

  @override
  Stream<LlmStreamEvent> sendUserMessageWithToolHandler({
    required String text,
    required Future<String> Function(String name, Map<String, dynamic> args)
        onToolCall,
    int maxToolRounds = 3,
  }) async* {
    if (_platformGuard && !Platform.isAndroid) {
      yield const LlmErrorEvent('Native LLM is Android-only.');
      return;
    }

    await _host.sendUserMessage(text);

    var toolRounds = 0;
    while (true) {
      final events = StreamController<LlmStreamEvent>();
      final bridge = FlutterLlmBridge.instance;
      bridge.beginGeneration(events);

      await _host.startGeneration();

      final resultFuture = bridge.waitForGenerationEnd();
      Object? result;
      await for (final event in events.stream) {
        yield event;
      }
      result = await resultFuture;

      bridge.endGeneration();

      if (result is Exception) {
        return;
      }

      if (result is! LlmFunctionCallResult) {
        return;
      }

      toolRounds++;
      if (toolRounds > maxToolRounds) {
        yield const LlmErrorEvent('Too many tool calls for one message.');
        return;
      }

      final call = result;
      final toolResult = await onToolCall(call.name, call.args);
      yield LlmToolResultEvent(name: call.name, result: toolResult);
      await _host.sendToolResult(call.name, toolResult);
    }
  }

  @override
  Future<void> stopGeneration() async {
    await _host.stopGeneration();
    FlutterLlmBridge.instance.endGeneration(reason: 'Generation cancelled');
  }

  @override
  Future<void> dispose() async {
    await _host.unloadModel();
    _loadedBackend = null;
  }
}
