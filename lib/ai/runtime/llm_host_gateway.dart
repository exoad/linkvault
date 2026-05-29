import '../../platform/app_api.g.dart' as pigeon;

/// Abstraction over [pigeon.LlmHostApi] for tests and [NativeLlmRuntime].
abstract class LlmHostGateway {
  Future<bool> isModelInstalled(String fileName);

  Future<void> startModelDownload(
    String url,
    String fileName,
    String? bearerToken,
  );

  Future<void> cancelModelDownload();

  Future<void> uninstallModel(String fileName);

  Future<void> loadModel(
    String fileName,
    pigeon.LlmBackend backend,
    int maxTokens,
  );

  Future<void> unloadModel();

  Future<void> resetConversation();

  Future<void> replayHistory(List<pigeon.LlmHistoryMessage> messages);

  Future<void> sendUserMessage(String text);

  Future<void> sendToolResult(String toolName, String resultJson);

  Future<void> startGeneration();

  Future<void> stopGeneration();

  Future<void> applyGenerationConfig(pigeon.LlmGenerationConfig config);

  Future<pigeon.LlmContextStats> getContextStats();
}

/// Production gateway delegating to Pigeon.
final class PigeonLlmHostGateway implements LlmHostGateway {
  PigeonLlmHostGateway([pigeon.LlmHostApi? api]) : _api = api ?? pigeon.LlmHostApi();

  final pigeon.LlmHostApi _api;

  @override
  Future<bool> isModelInstalled(String fileName) =>
      _api.isModelInstalled(fileName);

  @override
  Future<void> startModelDownload(
    String url,
    String fileName,
    String? bearerToken,
  ) =>
      _api.startModelDownload(url, fileName, bearerToken);

  @override
  Future<void> cancelModelDownload() => _api.cancelModelDownload();

  @override
  Future<void> uninstallModel(String fileName) =>
      _api.uninstallModel(fileName);

  @override
  Future<void> loadModel(
    String fileName,
    pigeon.LlmBackend backend,
    int maxTokens,
  ) =>
      _api.loadModel(fileName, backend, maxTokens);

  @override
  Future<void> unloadModel() => _api.unloadModel();

  @override
  Future<void> resetConversation() => _api.resetConversation();

  @override
  Future<void> replayHistory(List<pigeon.LlmHistoryMessage> messages) =>
      _api.replayHistory(messages);

  @override
  Future<void> sendUserMessage(String text) => _api.sendUserMessage(text);

  @override
  Future<void> sendToolResult(String toolName, String resultJson) =>
      _api.sendToolResult(toolName, resultJson);

  @override
  Future<void> startGeneration() => _api.startGeneration();

  @override
  Future<void> stopGeneration() => _api.stopGeneration();

  @override
  Future<void> applyGenerationConfig(pigeon.LlmGenerationConfig config) =>
      _api.applyGenerationConfig(config);

  @override
  Future<pigeon.LlmContextStats> getContextStats() => _api.getContextStats();
}
