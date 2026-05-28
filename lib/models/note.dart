class NoteModel {
  const NoteModel({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get displayTitle {
    final trimmed = title.trim();
    if (trimmed.isNotEmpty) return trimmed;
    final firstLine = body.trim().split(RegExp(r'\r?\n')).first.trim();
    if (firstLine.isNotEmpty) return firstLine;
    return 'Untitled note';
  }

  String get preview {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return 'No content yet';
    final lines = trimmed.split(RegExp(r'\r?\n'));
    final snippet = lines.take(3).join(' ').trim();
    if (snippet.length <= 120) return snippet;
    return '${snippet.substring(0, 117)}…';
  }
}
