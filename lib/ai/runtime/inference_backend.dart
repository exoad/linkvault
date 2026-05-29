import 'package:shared_preferences/shared_preferences.dart';

import '../../platform/app_api.g.dart';

/// User-selectable inference backend for native Gemma.
enum InferenceBackend {
  cpu,
  gpu,
}

extension InferenceBackendX on InferenceBackend {
  LlmBackend toPigeon() => switch (this) {
        InferenceBackend.cpu => LlmBackend.cpu,
        InferenceBackend.gpu => LlmBackend.gpu,
      };

  String get label => switch (this) {
        InferenceBackend.cpu => 'CPU',
        InferenceBackend.gpu => 'GPU',
      };
}

/// Persists chat inference backend preference.
class InferenceBackendPreferences {
  InferenceBackendPreferences(this._prefs);

  static const _key = 'chat_inference_backend';

  final SharedPreferences _prefs;

  static Future<InferenceBackendPreferences> load() async {
    return InferenceBackendPreferences(await SharedPreferences.getInstance());
  }

  InferenceBackend get backend {
    final raw = _prefs.getString(_key);
    return raw == InferenceBackend.cpu.name
        ? InferenceBackend.cpu
        : InferenceBackend.gpu;
  }

  Future<void> setBackend(InferenceBackend backend) async {
    await _prefs.setString(_key, backend.name);
  }
}
