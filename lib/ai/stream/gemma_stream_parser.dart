import '../runtime/local_llm_runtime.dart';

/// Splits model tokens into visible response vs reasoning blocks.
final class GemmaStreamParser {
  static final List<String> _openTags = [
    _tag('think'),
    _tag('thinking'),
    _tag('thought'),
  ];
  static final List<String> _closeTags = [
    _closeTag('think'),
    _closeTag('thinking'),
    _closeTag('thought'),
  ];

  static String _tag(String name) => '<$name>';
  static String _closeTag(String name) => '</$name>';

  bool _inThinking = false;
  final StringBuffer _carry = StringBuffer();

  List<LlmStreamEvent> push(String token) {
    if (_inThinking) {
      _carry.write(token);
      if (_mightBePartialClose(_carry.toString())) {
        return _drain();
      }
      final chunk = _carry.toString();
      _carry.clear();
      return [LlmThinkingTokenEvent(chunk), ..._drain()];
    }
    _carry.write(token);
    return _drain();
  }

  List<LlmStreamEvent> finish() {
    final tail = _carry.toString();
    _carry.clear();
    if (tail.isEmpty) return const [];

    if (_inThinking) {
      _inThinking = false;
      return [LlmThinkingDoneEvent(tail)];
    }
    return [LlmTokenEvent(tail)];
  }

  List<LlmStreamEvent> _drain() {
    final events = <LlmStreamEvent>[];

    while (true) {
      final text = _carry.toString();
      if (text.isEmpty) break;

      if (_inThinking) {
        final close = _findEarliestClose(text);
        if (close == null) {
          if (_mightBePartialClose(text)) break;
          _carry.clear();
          events.add(LlmThinkingTokenEvent(text));
          continue;
        }
        final before = text.substring(0, close.index);
        if (before.isNotEmpty) {
          events.add(LlmThinkingDoneEvent(before));
        }
        _carry
          ..clear()
          ..write(text.substring(close.index + close.tag.length));
        _inThinking = false;
        continue;
      }

      final open = _findEarliestOpen(text);
      if (open == null) {
        if (_mightBePartialOpen(text)) break;
        _carry.clear();
        events.add(LlmTokenEvent(text));
        continue;
      }

      final before = text.substring(0, open.index);
      if (before.isNotEmpty) {
        events.add(LlmTokenEvent(before));
      }
      _carry
        ..clear()
        ..write(text.substring(open.index + open.tag.length));
      _inThinking = true;
    }

    return events;
  }

  _TagMatch? _findEarliestOpen(String text) {
    final lower = text.toLowerCase();
    _TagMatch? best;
    for (final tag in _openTags) {
      final index = lower.indexOf(tag);
      if (index >= 0 && (best == null || index < best.index)) {
        best = _TagMatch(index, tag);
      }
    }
    return best;
  }

  _TagMatch? _findEarliestClose(String text) {
    final lower = text.toLowerCase();
    _TagMatch? best;
    for (final tag in _closeTags) {
      final index = lower.indexOf(tag);
      if (index >= 0 && (best == null || index < best.index)) {
        best = _TagMatch(index, tag);
      }
    }
    return best;
  }

  bool _mightBePartialOpen(String text) {
    final lower = text.toLowerCase();
    for (final tag in _openTags) {
      for (var i = 1; i < tag.length; i++) {
        if (lower.endsWith(tag.substring(0, i))) return true;
      }
    }
    return false;
  }

  bool _mightBePartialClose(String text) {
    final lower = text.toLowerCase();
    for (final tag in _closeTags) {
      for (var i = 1; i < tag.length; i++) {
        if (lower.endsWith(tag.substring(0, i))) return true;
      }
    }
    return false;
  }
}

final class _TagMatch {
  const _TagMatch(this.index, this.tag);
  final int index;
  final String tag;
}
