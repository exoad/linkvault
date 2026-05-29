import 'package:shared_preferences/shared_preferences.dart';

import '../../platform/app_api.g.dart' as pigeon;
import '../models/chat_model_registry.dart';

/// User-tunable sampling and context limits for on-device chat.
class ChatInferencePreferences {
  ChatInferencePreferences(this._prefs);

  static const _temperatureKey = 'chat_temperature';
  static const _topKKey = 'chat_top_k';
  static const _topPKey = 'chat_top_p';
  static const _maxOutputKey = 'chat_max_output_tokens';
  static const _contextLimitKey = 'chat_context_token_limit';

  static const defaultTemperature = 0.85;
  static const defaultTopK = 40;
  static const defaultTopP = 0.92;
  static const defaultMaxOutput = 768;
  static const defaultContextLimit = 8192;

  final SharedPreferences _prefs;

  static Future<ChatInferencePreferences> load() async {
    return ChatInferencePreferences(await SharedPreferences.getInstance());
  }

  double get temperature =>
      _prefs.getDouble(_temperatureKey) ?? defaultTemperature;

  int get topK => _prefs.getInt(_topKKey) ?? defaultTopK;

  double get topP => _prefs.getDouble(_topPKey) ?? defaultTopP;

  int get maxOutputTokens =>
      _prefs.getInt(_maxOutputKey) ?? defaultMaxOutput;

  int get contextTokenLimit =>
      _prefs.getInt(_contextLimitKey) ?? defaultContextLimit;

  Future<void> setTemperature(double value) async {
    await _prefs.setDouble(_temperatureKey, value.clamp(0.1, 2.0));
  }

  Future<void> setTopK(int value) async {
    await _prefs.setInt(_topKKey, value.clamp(1, 128));
  }

  Future<void> setTopP(double value) async {
    await _prefs.setDouble(_topPKey, value.clamp(0.05, 1.0));
  }

  Future<void> setMaxOutputTokens(int value) async {
    await _prefs.setInt(_maxOutputKey, value.clamp(64, 4096));
  }

  Future<void> setContextTokenLimit(int value) async {
    await _prefs.setInt(_contextLimitKey, value.clamp(1024, 32768));
  }

  pigeon.LlmGenerationConfig toPigeon() {
    return pigeon.LlmGenerationConfig(
      temperature: temperature,
      topK: topK,
      topP: topP,
      maxOutputTokens: maxOutputTokens,
      contextTokenLimit: contextTokenLimit,
    );
  }

  int get registryCap => ChatModelRegistry.defaultModel.maxTokens;
}
