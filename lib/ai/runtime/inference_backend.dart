import 'package:flutter_gemma/pigeon.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User-selectable inference backend (maps to [PreferredBackend] at runtime).
enum InferenceBackend {
  cpu,
  gpu,
}

extension InferenceBackendX on InferenceBackend {
  PreferredBackend toPreferredBackend() => switch (this) {
        InferenceBackend.cpu => PreferredBackend.cpu,
        InferenceBackend.gpu => PreferredBackend.gpu,
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
