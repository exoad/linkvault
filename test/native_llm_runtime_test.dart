import 'package:flutter_test/flutter_test.dart';
import 'package:linkvault/ai/chat/flutter_llm_bridge.dart';
import 'package:linkvault/ai/runtime/inference_backend.dart';
import 'package:linkvault/ai/runtime/local_llm_runtime.dart';
import 'package:linkvault/ai/runtime/native_llm_runtime.dart';

import 'fakes/fake_llm_host.dart';

void main() {
  late FakeLlmHostGateway host;
  late NativeLlmRuntime runtime;

  setUp(() {
    host = FakeLlmHostGateway();
    runtime = NativeLlmRuntime.testing(host: host);
    FlutterLlmBridge.instance.endGeneration();
  });

  test('installModel waits for download and verifies file', () async {
    host.modelInstalled = true;
    final progress = <int>[];
    await runtime.installModel(onProgress: progress.add);
    expect(progress, contains(100));
    expect(await runtime.isModelInstalled(), isTrue);
  });

  test('ensureReady records backend', () async {
    await runtime.ensureReady(
      backend: InferenceBackend.gpu,
      generationConfig: null,
    );
    expect(runtime.activeBackend, InferenceBackend.gpu);
    expect(host.lastLoadedBackend, isNotNull);
  });

  test('sendUserMessageWithToolHandler streams tokens to done', () async {
    await runtime.ensureReady(
      backend: InferenceBackend.cpu,
      generationConfig: null,
    );
    host.nextGeneration = TokenStreamPlan(
      tokens: ['Hello', ' world'],
      fullText: 'Hello world',
    );

    final events = await runtime
        .sendUserMessageWithToolHandler(
          text: 'Hi',
          onToolCall: (_, _) async => '',
        )
        .toList();

    expect(host.userMessages, ['Hi']);
    expect(events.whereType<LlmTokenEvent>().map((e) => e.token).join(), 'Hello world');
    expect(events.whereType<LlmDoneEvent>().single.fullText, 'Hello world');
  });

  test('tool loop executes handler and sends result to host', () async {
    await runtime.ensureReady(
      backend: InferenceBackend.cpu,
      generationConfig: null,
    );

    host.generationQueue.addAll([
      FunctionCallPlan(name: 'search_links', args: {'query': 'dart'}),
      TokenStreamPlan(tokens: ['Done'], fullText: 'Done'),
    ]);

    var handlerCalls = 0;
    final events = await runtime
        .sendUserMessageWithToolHandler(
          text: 'find links',
          onToolCall: (name, args) async {
            handlerCalls++;
            expect(name, 'search_links');
            expect(args['query'], 'dart');
            return '{"results":[]}';
          },
          maxToolRounds: 2,
        )
        .toList();

    expect(handlerCalls, 1);
    expect(events.whereType<LlmToolCallEvent>(), isNotEmpty);
    expect(events.whereType<LlmToolResultEvent>(), isNotEmpty);
    expect(events.whereType<LlmDoneEvent>().single.fullText, 'Done');
    expect(host.toolResults.single.name, 'search_links');
    expect(host.toolResults.single.result, '{"results":[]}');
  });

  test('maxToolRounds exceeded yields error', () async {
    await runtime.ensureReady(
      backend: InferenceBackend.cpu,
      generationConfig: null,
    );
    host.nextGeneration = FunctionCallPlan(name: 'a', args: {});

    final events = await runtime
        .sendUserMessageWithToolHandler(
          text: 'x',
          onToolCall: (_, _) async => 'ok',
          maxToolRounds: 0,
        )
        .toList();

    expect(
      events.whereType<LlmErrorEvent>().single.message,
      'Too many tool calls for one message.',
    );
  });

  test('generation error surfaces as LlmErrorEvent', () async {
    await runtime.ensureReady(
      backend: InferenceBackend.cpu,
      generationConfig: null,
    );
    host.nextGeneration = ErrorPlan(code: 'GEN', message: 'boom');

    final events = await runtime
        .sendUserMessageWithToolHandler(
          text: 'fail',
          onToolCall: (_, _) async => '',
        )
        .toList();

    final errors = events.whereType<LlmErrorEvent>().toList();
    expect(errors, isNotEmpty);
    expect(errors.first.message, contains('boom'));
  });
}
