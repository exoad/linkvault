import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:linkvault/ai/chat/flutter_llm_bridge.dart';
import 'package:linkvault/ai/runtime/local_llm_runtime.dart';

void main() {
  final bridge = FlutterLlmBridge.instance;

  tearDown(() {
    bridge.endGeneration();
    bridge.setDownloadListener(null);
  });

  test('onDownloadProgress completes waitForDownloadComplete at 100%', () async {
    final done = bridge.waitForDownloadComplete();
    bridge.onDownloadProgress(50);
    bridge.onDownloadProgress(100);
    await expectLater(done, completes);
  });

  test('onToken and onGenerationComplete emit stream events', () async {
    final controller = StreamController<LlmStreamEvent>();
    bridge.beginGeneration(controller);

    bridge.onToken('Hi');
    bridge.onGenerationComplete('');

    final events = await controller.stream.toList();
    expect(events, hasLength(2));
    expect(events[0], isA<LlmTokenEvent>());
    expect((events[0] as LlmTokenEvent).token, 'Hi');
    expect(events[1], isA<LlmDoneEvent>());
    expect((events[1] as LlmDoneEvent).fullText, 'Hi');
  });

  test('onGenerationComplete uses provided fullText over buffer', () async {
    final controller = StreamController<LlmStreamEvent>();
    bridge.beginGeneration(controller);

    bridge.onToken('ignored');
    bridge.onGenerationComplete('Final');

    final events = await controller.stream.toList();
    expect(events.last, isA<LlmDoneEvent>());
    expect((events.last as LlmDoneEvent).fullText, 'Final');
  });

  test('onFunctionCall completes with LlmFunctionCallResult', () async {
    final controller = StreamController<LlmStreamEvent>();
    bridge.beginGeneration(controller);

    bridge.onFunctionCall('search_links', '{"query":"flutter"}'); // ignore

    final events = await controller.stream.toList();
    expect(events, hasLength(1));
    expect(events.single, isA<LlmToolCallEvent>());

    final result = await bridge.waitForGenerationEnd();
    expect(result, isA<LlmFunctionCallResult>());
    final call = result! as LlmFunctionCallResult;
    expect(call.name, 'search_links');
    expect(call.args['query'], 'flutter');
  });

  test('onLlmError fails active generation', () async {
    final controller = StreamController<LlmStreamEvent>();
    bridge.beginGeneration(controller);

    bridge.onLlmError('LOAD_FAILED', 'bad model');

    final events = await controller.stream.toList();
    expect(events, hasLength(1));
    expect(events.single, isA<LlmErrorEvent>());
    expect((events.single as LlmErrorEvent).message, 'LOAD_FAILED: bad model');
    final result = await bridge.waitForGenerationEnd();
    expect(result, isA<Exception>());
  });
}
