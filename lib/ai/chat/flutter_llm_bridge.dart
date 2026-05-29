import 'dart:async';
import 'dart:convert';

import '../../platform/app_api.g.dart';
import '../runtime/local_llm_runtime.dart';
import '../stream/gemma_stream_parser.dart';

/// Native → Dart LLM events (Kotlin [FlutterLlmApi]).
final class FlutterLlmBridge extends FlutterLlmApi {
  FlutterLlmBridge._();

  static final FlutterLlmBridge instance = FlutterLlmBridge._();

  static void install() {
    FlutterLlmApi.setUp(instance);
  }

  _ActiveGeneration? _active;
  void Function(int percent)? _downloadListener;
  Completer<void>? _downloadCompleter;

  void setDownloadListener(void Function(int percent)? listener) {
    _downloadListener = listener;
  }

  Future<void> waitForDownloadComplete() {
    _downloadCompleter = Completer<void>();
    return _downloadCompleter!.future;
  }

  void beginGeneration(StreamController<LlmStreamEvent> controller) {
    _active = _ActiveGeneration(controller);
  }

  void endGeneration() {
    _active = null;
  }

  Future<Object?> waitForGenerationEnd() {
    final active = _active;
    if (active == null) {
      return Future.value(null);
    }
    return active.completer.future;
  }

  void _emitParsed(LlmStreamEvent event) {
    final active = _active;
    if (active == null) return;
    active.controller.add(event);
    switch (event) {
      case LlmTokenEvent(:final token):
        active.responseBuffer.write(token);
      case LlmThinkingTokenEvent(:final token):
        active.thinkingBuffer.write(token);
      case LlmThinkingDoneEvent(:final fullText):
        active.thinkingBuffer.write(fullText);
      default:
        break;
    }
  }

  @override
  void onDownloadProgress(int percent) {
    _downloadListener?.call(percent);
    if (percent >= 100) {
      _downloadCompleter?.complete();
      _downloadCompleter = null;
    }
  }

  @override
  void onToken(String token) {
    final active = _active;
    if (active == null) return;
    for (final event in active.parser.push(token)) {
      _emitParsed(event);
    }
  }

  @override
  void onGenerationComplete(String fullText) {
    final active = _active;
    if (active == null) return;

    for (final event in active.parser.finish()) {
      _emitParsed(event);
    }

    final response = fullText.isNotEmpty
        ? fullText
        : active.responseBuffer.toString();
    active.controller.add(LlmDoneEvent(response));
    active.controller.close();
    active.completer.complete(null);
  }

  @override
  void onFunctionCall(String name, String argsJson) {
    Map<String, dynamic> args = {};
    try {
      final decoded = jsonDecode(argsJson);
      if (decoded is Map<String, dynamic>) {
        args = decoded;
      } else if (decoded is Map) {
        args = Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    final summary = args.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    final active = _active;
    if (active == null) return;

    for (final event in active.parser.finish()) {
      _emitParsed(event);
    }

    active.controller.add(
      LlmToolCallEvent(name: name, args: args, argsSummary: summary),
    ); // args forwarded for UI
    active.controller.close();
    active.completer.complete(LlmFunctionCallResult(name: name, args: args));
  }

  @override
  void onLlmError(String code, String message) {
    final active = _active;
    if (active != null) {
      active.controller.add(LlmErrorEvent('$code: $message'));
      active.controller.close();
      if (!active.completer.isCompleted) {
        active.completer.complete(Exception('$code: $message'));
      }
    }
    _downloadCompleter?.completeError(Exception('$code: $message'));
    _downloadCompleter = null;
  }
}

/// Emitted when Kotlin detects a tool call in model output.
final class LlmFunctionCallResult {
  const LlmFunctionCallResult({required this.name, required this.args});
  final String name;
  final Map<String, dynamic> args;
}

final class _ActiveGeneration {
  _ActiveGeneration(this.controller) : completer = Completer<Object?>();

  final StreamController<LlmStreamEvent> controller;
  final Completer<Object?> completer;
  final GemmaStreamParser parser = GemmaStreamParser();
  final StringBuffer responseBuffer = StringBuffer();
  final StringBuffer thinkingBuffer = StringBuffer();
}
