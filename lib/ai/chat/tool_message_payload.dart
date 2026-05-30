import 'dart:convert';

/// Parsed [ChatMessageRole.tool] row (`args` + optional `result` JSON).
final class ToolMessagePayload {
  const ToolMessagePayload({required this.argsSummary, this.result});

  final String argsSummary;
  final String? result;

  bool get hasResult => result != null && result!.isNotEmpty;

  static String encode({required String argsSummary, String? result}) {
    return jsonEncode({
      'args': argsSummary,
      ...?(result == null ? null : {'result': result}),
    });
  }

  static ToolMessagePayload parse(String content) {
    try {
      final decoded = jsonDecode(content);
      if (decoded is Map<String, dynamic>) {
        return ToolMessagePayload(
          argsSummary: decoded['args']?.toString() ?? content,
          result: decoded['result']?.toString(),
        );
      }
    } catch (_) {}
    return ToolMessagePayload(argsSummary: content);
  }
}
