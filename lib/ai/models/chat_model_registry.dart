import 'package:flutter_gemma/core/model.dart';

import 'chat_model_definition.dart';

/// Registry of on-device chat models (v1: single Gemma E2B entry).
abstract final class ChatModelRegistry {
  static const gemma4E2b = ChatModelDefinition(
    id: 'gemma-4-e2b',
    displayName: 'Gemma 4 E2B',
    modelType: ModelType.gemmaIt,
    installUrl:
        'https://huggingface.co/google/gemma-3n-E2B-it-litert-preview/resolve/main/gemma-3n-E2B-it-int4.task',
    modelFileName: 'gemma-3n-E2B-it-int4.task',
    sizeLabel: '~3.1 GB',
    needsHuggingFaceAuth: true,
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
