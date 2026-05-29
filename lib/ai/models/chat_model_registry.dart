import 'chat_model_definition.dart';

/// Registry of on-device chat models (v1: Gemma 4 E2B via LiteRT-LM).
abstract final class ChatModelRegistry {
  /// [google/gemma-4-E2B](https://huggingface.co/google/gemma-4-E2B) on-device bundle:
  /// [litert-community/gemma-4-E2B-it-litert-lm](https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm)
  static const gemma4E2b = ChatModelDefinition(
    id: 'gemma-4-e2b',
    displayName: 'Gemma 4 E2B',
    installUrl:
        'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm',
    modelFileName: 'gemma-4-E2B-it.litertlm',
    sizeLabel: '~2.6 GB',
    needsHuggingFaceAuth: false,
    maxTokens: 512,
  );

  static const List<ChatModelDefinition> all = [gemma4E2b];

  static ChatModelDefinition? findById(String id) {
    for (final model in all) {
      if (model.id == id) return model;
    }
    return null;
  }

  static ChatModelDefinition get defaultModel => gemma4E2b;
}
