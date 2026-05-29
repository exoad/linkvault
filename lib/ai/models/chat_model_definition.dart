import '../runtime/inference_backend.dart';

/// Metadata for a downloadable on-device chat model.
class ChatModelDefinition {
  const ChatModelDefinition({
    required this.id,
    required this.displayName,
    required this.installUrl,
    required this.modelFileName,
    required this.sizeLabel,
    this.needsHuggingFaceAuth = false,
    this.maxTokens = 512,
    this.defaultBackend = InferenceBackend.gpu,
  });

  final String id;
  final String displayName;
  final String installUrl;
  final String modelFileName;
  final String sizeLabel;
  final bool needsHuggingFaceAuth;
  final int maxTokens;
  final InferenceBackend defaultBackend;
}
