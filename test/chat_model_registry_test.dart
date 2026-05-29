import 'package:flutter_test/flutter_test.dart';
import 'package:linkvault/ai/models/chat_model_registry.dart';

void main() {
  test('default model is Gemma 4 E2B litert bundle', () {
    final model = ChatModelRegistry.defaultModel;
    expect(model.id, 'gemma-4-e2b');
    expect(model.modelFileName, endsWith('.litertlm'));
    expect(model.installUrl, contains('huggingface.co'));
    expect(model.needsHuggingFaceAuth, isFalse);
  });

  test('findById returns known models only', () {
    expect(ChatModelRegistry.findById('gemma-4-e2b'), isNotNull);
    expect(ChatModelRegistry.findById('unknown'), isNull);
  });
}
