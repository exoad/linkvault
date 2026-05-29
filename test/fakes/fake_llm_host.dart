import 'dart:convert';

import 'package:linkvault/ai/chat/flutter_llm_bridge.dart';
import 'package:linkvault/ai/runtime/llm_host_gateway.dart';
import 'package:linkvault/platform/app_api.g.dart' as pigeon;

/// Configurable [LlmHostGateway] for unit tests (drives [FlutterLlmBridge]).
final class FakeLlmHostGateway implements LlmHostGateway {
  bool modelInstalled = true;
  FakeGenerationPlan? nextGeneration;
  final List<FakeGenerationPlan> generationQueue = [];
  final List<String> userMessages = [];
  final List<({String name, String result})> toolResults = [];
  pigeon.LlmBackend? lastLoadedBackend;

  @override
  Future<bool> isModelInstalled(String fileName) async => modelInstalled;

  @override
  Future<void> startModelDownload(
    String url,
    String fileName,
    String? bearerToken,
  ) async {
    FlutterLlmBridge.instance.onDownloadProgress(100);
  }

  @override
  Future<void> cancelModelDownload() async {}

  @override
  Future<void> uninstallModel(String fileName) async {
    modelInstalled = false;
  }

  @override
  Future<void> loadModel(
    String fileName,
    pigeon.LlmBackend backend,
    int maxTokens,
  ) async {
    lastLoadedBackend = backend;
  }

  @override
  Future<void> unloadModel() async {}

  @override
  Future<void> resetConversation() async {}

  @override
  Future<void> replayHistory(List<pigeon.LlmHistoryMessage> messages) async {}

  @override
  Future<void> sendUserMessage(String text) async {
    userMessages.add(text);
  }

  @override
  Future<void> sendToolResult(String toolName, String resultJson) async {
    toolResults.add((name: toolName, result: resultJson));
  }

  FakeGenerationPlan? _dequeuePlan() {
    if (generationQueue.isNotEmpty) {
      return generationQueue.removeAt(0);
    }
    return nextGeneration;
  }

  @override
  Future<void> startGeneration() async {
    final plan = _dequeuePlan();
    if (plan == null) {
      FlutterLlmBridge.instance.onGenerationComplete('');
      return;
    }
    await Future<void>.delayed(Duration.zero);
    final bridge = FlutterLlmBridge.instance;
    switch (plan) {
      case TokenStreamPlan(:final tokens, :final fullText):
        for (final token in tokens) {
          bridge.onToken(token);
        }
        bridge.onGenerationComplete(fullText ?? tokens.join());
      case FunctionCallPlan(:final name, :final args):
        bridge.onFunctionCall(name, jsonEncode(args)); // ignore: args used in json
      case ErrorPlan(:final code, :final message):
        bridge.onLlmError(code, message);
    }
  }

  @override
  Future<void> stopGeneration() async {}

  int contextUsed = 120;
  int contextMax = 8192;

  @override
  Future<void> applyGenerationConfig(pigeon.LlmGenerationConfig config) async {}

  @override
  Future<pigeon.LlmContextStats> getContextStats() async {
    return pigeon.LlmContextStats(usedTokens: contextUsed, maxTokens: contextMax);
  }
}

sealed class FakeGenerationPlan {}

final class TokenStreamPlan extends FakeGenerationPlan {
  TokenStreamPlan({required this.tokens, this.fullText});

  final List<String> tokens;
  final String? fullText;
}

final class FunctionCallPlan extends FakeGenerationPlan {
  FunctionCallPlan({required this.name, required this.args});

  final String name;
  final Map<String, dynamic> args;
}

final class ErrorPlan extends FakeGenerationPlan {
  ErrorPlan({required this.code, required this.message});

  final String code;
  final String message;
}
