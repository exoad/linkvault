import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/app_database.dart';

/// Exports all local Drift data as a shareable JSON backup.
final class DataExportService {
  DataExportService(this._database);

  final AppDatabase _database;

  static const exportVersion = 1;

  Future<void> exportAndShare() async {
    final payload = await buildPayload();
    final json = const JsonEncoder.withIndent('  ').convert(payload);
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
    final path = p.join(dir.path, 'linkvault-export-$stamp.json');
    final file = File(path);
    await file.writeAsString(json);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path)],
        subject: 'Linkvault backup',
        text: 'Linkvault data export',
      ),
    );
  }

  Future<Map<String, dynamic>> buildPayload() async {
    final folders = await _database.select(_database.folders).get();
    final bookmarks = await _database.select(_database.bookmarks).get();
    final notes = await _database.select(_database.notes).get();
    final chatSessions = await _database.select(_database.chatSessions).get();
    final chatMessages = await _database.select(_database.chatMessages).get();

    return {
      'version': exportVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'folders': folders.map((row) => row.toJson()).toList(),
      'bookmarks': bookmarks.map((row) => row.toJson()).toList(),
      'notes': notes.map((row) => row.toJson()).toList(),
      'chatSessions': chatSessions.map((row) => row.toJson()).toList(),
      'chatMessages': chatMessages.map((row) => row.toJson()).toList(),
    };
  }
}
