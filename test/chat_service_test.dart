import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkvault/ai/chat/chat_hf_token_preferences.dart';
import 'package:linkvault/ai/chat/chat_inference_preferences.dart';
import 'package:linkvault/ai/chat/chat_service.dart';
import 'package:linkvault/ai/chat/chat_session_preferences.dart';
import 'package:linkvault/ai/runtime/inference_backend.dart';
import 'package:linkvault/ai/runtime/local_llm_runtime.dart';
import 'package:linkvault/ai/tools/tool_registry.dart';
import 'package:linkvault/data/app_database.dart';
import 'package:linkvault/data/chat_repository.dart';
import 'package:linkvault/models/chat_message.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_llm_host.dart';
import 'package:linkvault/ai/runtime/native_llm_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ChatRepository repository;
  late InferenceBackendPreferences backendPrefs;
  late ChatHfTokenPreferences hfTokenPrefs;
  late ChatInferencePreferences inferencePrefs;
  late ChatSessionPreferences sessionPrefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = ChatRepository(database: db);
    backendPrefs = await InferenceBackendPreferences.load();
    hfTokenPrefs = await ChatHfTokenPreferences.load();
    inferencePrefs = await ChatInferencePreferences.load();
    sessionPrefs = await ChatSessionPreferences.load();
  });

  ChatService testService(FakeLlmHostGateway host) => ChatService(
        repository: repository,
        runtime: NativeLlmRuntime.testing(host: host),
        toolRegistry: ToolRegistry(),
        backendPrefs: backendPrefs,
        hfTokenPrefs: hfTokenPrefs,
        inferencePrefs: inferencePrefs,
        sessionPrefs: sessionPrefs,
      );

  tearDown(() async {
    await db.close();
  });

  test('sendMessage persists user, tool, and assistant rows', () async {
    final host = FakeLlmHostGateway();
    host.generationQueue.addAll([
      FunctionCallPlan(name: 'get_current_time', args: {}),
      TokenStreamPlan(tokens: ['It is noon'], fullText: 'It is noon'),
    ]);

    final service = testService(host);

    final sessionId = await service.createSession();
    await service.ensureModelReady();

    final events = await service
        .sendMessage(sessionId: sessionId, text: 'What time is it?')
        .toList();

    expect(events.whereType<LlmToolCallEvent>(), isNotEmpty);
    expect(events.whereType<LlmDoneEvent>().single.fullText, 'It is noon');

    final messages = await repository.getMessages(sessionId);
    expect(messages.any((m) => m.role == ChatMessageRole.user), isTrue);
    expect(messages.any((m) => m.role == ChatMessageRole.tool), isTrue);
    expect(messages.any((m) => m.role == ChatMessageRole.assistant), isTrue);
  });

  test('prepareSession reports progress steps', () async {
    final host = FakeLlmHostGateway();
    final service = testService(host);
    final sessionId = await service.createSession();
    final steps = <ChatPrepareStep>[];
    await service.prepareSession(sessionId, onProgress: steps.add);
    expect(steps.first, ChatPrepareStep.loadingModel);
    expect(steps.last, ChatPrepareStep.done);
  });

  test('createSession then prepareSession loads runtime backend', () async {
    final host = FakeLlmHostGateway();
    final service = testService(host);

    final sessionId = await service.createSession();
    expect(service.activeBackend, isNull);

    await service.prepareSession(sessionId);

    expect(service.activeBackend, isNotNull);
    expect(host.lastLoadedBackend, isNotNull);
  });

  test('sendMessage streams assistant reply without tools', () async {
    final host = FakeLlmHostGateway();
    host.nextGeneration = TokenStreamPlan(
      tokens: ['Sure'],
      fullText: 'Sure',
    );

    final service = testService(host);

    final sessionId = await service.createSession();
    await service.ensureModelReady();

    final events = await service
        .sendMessage(sessionId: sessionId, text: 'Hi')
        .toList();

    expect(events.whereType<LlmTokenEvent>().map((e) => e.token).join(), 'Sure');
    final messages = await repository.getMessages(sessionId);
    expect(
      messages.where((m) => m.role == ChatMessageRole.assistant).single.content,
      'Sure',
    );
  });
}
