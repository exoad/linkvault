import 'package:flutter_gemma/core/tool.dart';

import 'chat_tool.dart';
import 'get_current_time_tool.dart';
import 'open_url_tool.dart';
import 'web_search_tool.dart';

/// Registers app tools and builds Gemma [Tool] declarations.
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

  List<Tool> get gemmaTools => _tools.values
      .map(
        (t) => Tool(
          name: t.name,
          description: t.description,
          parameters: t.parametersSchema,
        ),
      )
      .toList();

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
