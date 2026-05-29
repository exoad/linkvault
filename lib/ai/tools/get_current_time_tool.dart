import 'chat_tool.dart';

final class GetCurrentTimeTool implements ChatTool {
  @override
  String get name => 'get_current_time';

  @override
  String get label => 'Current time';

  @override
  String get description =>
      'Returns the current local date, time, and timezone name.';

  @override
  Map<String, dynamic> get parametersSchema => {
        'type': 'object',
        'properties': <String, dynamic>{},
      };

  @override
  Future<String> execute(Map<String, dynamic> args) async {
    final now = DateTime.now();
    final offset = now.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes =
        (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    return '${now.toIso8601String()} (${now.timeZoneName}, UTC$sign$hours:$minutes)';
  }
}
