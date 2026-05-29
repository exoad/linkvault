import 'package:flutter_test/flutter_test.dart';
import 'package:linkvault/ai/tools/get_current_time_tool.dart';
import 'package:linkvault/ai/tools/tool_registry.dart';
import 'package:linkvault/ai/tools/web_search_tool.dart';

void main() {
  test('get_current_time returns ISO timestamp', () async {
    final tool = GetCurrentTimeTool();
    final result = await tool.execute({});
    expect(result, contains('T'));
  });

  test('tool registry has three default tools', () {
    expect(ToolRegistry.defaultTools.length, 3);
  });

  test('web_search handles empty query', () async {
    final tool = WebSearchTool();
    final result = await tool.execute({});
    expect(result, contains('required'));
  });
}
