import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/bookmark.dart';
import '../../widgets/bookmark_actions_sheet.dart';
import '../edit_link/edit_bookmark_sheet.dart';

Future<void> handleBookmarkTap(
  BuildContext context,
  BookmarkModel bookmark,
) async {
  final action = await showBookmarkActionsSheet(context);
  if (!context.mounted || action == null) return;

  switch (action) {
    case BookmarkAction.open:
      await _openUrl(context, bookmark.url);
    case BookmarkAction.copy:
      await Clipboard.setData(ClipboardData(text: bookmark.url));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('URL copied')),
        );
      }
    case BookmarkAction.edit:
      await showEditBookmarkSheet(context, bookmark: bookmark);
  }
}

Future<void> _openUrl(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open URL')),
    );
  }
}
