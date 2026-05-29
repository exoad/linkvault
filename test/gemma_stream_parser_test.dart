import 'package:flutter_test/flutter_test.dart';
import 'package:linkvault/ai/runtime/local_llm_runtime.dart';
import 'package:linkvault/ai/stream/gemma_stream_parser.dart';

void main() {
  const thinkOpen = '<' 'think' '>';
  const thinkClose = '</' 'think' '>';

  test('splits think block from response', () {
    final parser = GemmaStreamParser();
    final events = <LlmStreamEvent>[
      ...parser.push('Before '),
      ...parser.push('$thinkOpen hidden reasoning$thinkClose'),
      ...parser.push(' after'),
      ...parser.finish(),
    ];

    expect(events.whereType<LlmTokenEvent>().map((e) => e.token).join(), 'Before  after');
    expect(
      events.whereType<LlmThinkingDoneEvent>().map((e) => e.fullText).join(),
      contains('hidden reasoning'),
    );
  });

  test('finish flushes open thinking', () {
    final parser = GemmaStreamParser();
    final events = parser.push('$thinkOpen still going');
    final tail = parser.finish();
    final thinking = [
      ...events.whereType<LlmThinkingTokenEvent>().map((e) => e.token),
      ...tail.whereType<LlmThinkingDoneEvent>().map((e) => e.fullText),
    ].join();
    expect(thinking, contains('still'));
  });
}
