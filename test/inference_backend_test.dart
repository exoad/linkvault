import 'package:flutter_test/flutter_test.dart';
import 'package:linkvault/ai/runtime/inference_backend.dart';
import 'package:linkvault/platform/app_api.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('backend maps to pigeon enum', () {
    expect(InferenceBackend.cpu.toPigeon(), LlmBackend.cpu);
    expect(InferenceBackend.gpu.toPigeon(), LlmBackend.gpu);
  });

  test('preferences persist backend choice', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await InferenceBackendPreferences.load();
    expect(prefs.backend, InferenceBackend.gpu);

    await prefs.setBackend(InferenceBackend.cpu);
    expect(prefs.backend, InferenceBackend.cpu);
  });
}
