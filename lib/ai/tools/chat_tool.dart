/// App-defined tool callable by the on-device model.
abstract class ChatTool {
  String get name;

  /// Short UI label (defaults to [name]).
  String get label => name;

  String get description;
  Map<String, dynamic> get parametersSchema;

  Future<String> execute(Map<String, dynamic> args);
}
