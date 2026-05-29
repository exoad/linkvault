import 'chat_tool.dart';
import 'get_current_time_tool.dart';
import 'open_url_tool.dart';
import 'web_search_tool.dart';

/// Registers app tools executed when the model requests a function call.
final class ToolRegistry {
  ToolRegistry({
    List<ChatTool>? tools,
  }) : _tools = {
          for (final t in tools ?? defaultTools) t.name: t,
        };

  static final defaultTools = <ChatTool>[
    GetCurrentTimeTool(),
    WebSearchTool(),
    OpenUrlTool(),
  ];

  final Map<String, ChatTool> _tools;

  String labelFor(String name) {
    final tool = _tools[name];
    if (tool == null) return name;
    return tool.label;
  }

  Future<String> execute(String name, Map<String, dynamic> args) async {
    final tool = _tools[name];
    if (tool == null) {
      return 'Error: unknown tool "$name".';
    }
    try {
      return await tool.execute(args);
    } catch (e) {
      return 'Error running $name: $e';
    }
  }
}
