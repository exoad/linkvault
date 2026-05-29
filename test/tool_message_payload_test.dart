import 'package:flutter_test/flutter_test.dart';
import 'package:linkvault/ai/chat/tool_message_payload.dart';

void main() {
  test('encode and parse tool rows', () {
    final raw = ToolMessagePayload.encode(
      argsSummary: 'query: flutter',
      result: '{"ok":true}',
    );
    final parsed = ToolMessagePayload.parse(raw);
    expect(parsed.argsSummary, 'query: flutter');
    expect(parsed.result, '{"ok":true}');
    expect(parsed.hasResult, isTrue);
  });
}
