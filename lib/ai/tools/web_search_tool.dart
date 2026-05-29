import 'dart:convert';

import 'package:http/http.dart' as http;

import 'chat_tool.dart';

/// DuckDuckGo Instant Answer API (no API key).
final class WebSearchTool implements ChatTool {
  WebSearchTool({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _endpoint = 'https://api.duckduckgo.com/';

  @override
  String get name => 'web_search';

  @override
  String get label => 'Web search';

  @override
  String get description =>
      'Search the web for a short factual summary. Requires network.';

  @override
  Map<String, dynamic> get parametersSchema => {
        'type': 'object',
        'properties': {
          'query': {
            'type': 'string',
            'description': 'Search query',
          },
        },
        'required': ['query'],
      };

  @override
  Future<String> execute(Map<String, dynamic> args) async {
    final query = (args['query'] as String?)?.trim();
    if (query == null || query.isEmpty) {
      return 'Error: query is required.';
    }

    final uri = Uri.parse(_endpoint).replace(
      queryParameters: {
        'q': query,
        'format': 'json',
        'no_redirect': '1',
        'no_html': '1',
      },
    );

    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      return 'Search failed (HTTP ${response.statusCode}).';
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final buffer = StringBuffer();

    final abstract = data['AbstractText'] as String?;
    if (abstract != null && abstract.isNotEmpty) {
      buffer.writeln(abstract);
      final source = data['AbstractSource'] as String?;
      if (source != null && source.isNotEmpty) {
        buffer.writeln('Source: $source');
      }
    }

    final answer = data['Answer'] as String?;
    if (answer != null && answer.isNotEmpty) {
      buffer.writeln(answer);
    }

    final related = data['RelatedTopics'] as List<dynamic>?;
    if (related != null && related.isNotEmpty) {
      buffer.writeln('Related:');
      var count = 0;
      for (final item in related) {
        if (count >= 5) break;
        if (item is Map<String, dynamic>) {
          final text = item['Text'] as String?;
          if (text != null && text.isNotEmpty) {
            buffer.writeln('- $text');
            count++;
          }
        }
      }
    }

    if (buffer.isEmpty) {
      return 'No instant answer found for "$query". Try rephrasing.';
    }
    return buffer.toString().trim();
  }
}
