import 'package:flutter_gemma/core/model.dart';
import 'package:flutter_gemma/pigeon.g.dart';

/// Metadata for a downloadable on-device chat model.
class ChatModelDefinition {
  const ChatModelDefinition({
    required this.id,
    required this.displayName,
    required this.modelType,
    required this.installUrl,
    required this.modelFileName,
    required this.sizeLabel,
    this.needsHuggingFaceAuth = false,
    this.modelFileType = ModelFileType.task,
    this.maxTokens = 4096,
    this.supportsFunctionCalls = true,
    this.defaultBackend = PreferredBackend.gpu,
  });

  final String id;
  final String displayName;
  final ModelType modelType;
  final String installUrl;
  final String modelFileName;
  final String sizeLabel;
  final bool needsHuggingFaceAuth;
  final ModelFileType modelFileType;
  final int maxTokens;
  final bool supportsFunctionCalls;
  final PreferredBackend defaultBackend;
}
