import 'package:flutter/material.dart';

import '../../animations/animated_sheet.dart';
import '../../app_scope.dart';
import '../../models/bookmark.dart';
import '../../models/folder.dart';
import '../../services/url_normalizer.dart';

Future<void> showEditBookmarkSheet(
  BuildContext context, {
  required BookmarkModel bookmark,
}) {
  return showAppBottomSheet<void>(
    context: context,
    builder: (context) => EditBookmarkSheet(bookmark: bookmark),
  );
}

class EditBookmarkSheet extends StatefulWidget {
  const EditBookmarkSheet({super.key, required this.bookmark});

  final BookmarkModel bookmark;

  @override
  State<EditBookmarkSheet> createState() => _EditBookmarkSheetState();
}

class _EditBookmarkSheetState extends State<EditBookmarkSheet> {
  late final TextEditingController _urlController;
  late final TextEditingController _titleController;
  String? _selectedFolderId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.bookmark.url);
    _titleController = TextEditingController(text: widget.bookmark.title);
    _selectedFolderId = widget.bookmark.folderId;
  }

  @override
  void dispose() {
    _urlController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  bool get _canSave =>
      !_saving &&
      UrlNormalizer.isValid(_urlController.text) &&
      _titleController.text.trim().isNotEmpty &&
      _selectedFolderId != null;

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    try {
      await AppScope.of(context).updateBookmark(
        id: widget.bookmark.id,
        rawUrl: _urlController.text,
        title: _titleController.text.trim(),
        folderId: _selectedFolderId,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showAnimatedDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete bookmark?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await AppScope.of(context).deleteBookmark(widget.bookmark.id);
    if (mounted) {
      Navigator.pop(context);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final repo = AppScope.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Edit bookmark', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: _urlController,
            keyboardType: TextInputType.url,
            autofillHints: const [AutofillHints.url],
            decoration: const InputDecoration(
              labelText: 'URL',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<FolderModel>>(
            stream: repo.watchFolders(),
            builder: (context, snapshot) {
              final folders = snapshot.data ?? [];
              return DropdownButtonFormField<String>(
                initialValue: _selectedFolderId,
                decoration: const InputDecoration(
                  labelText: 'Folder',
                  border: OutlineInputBorder(),
                ),
                items: folders
                    .map(
                      (f) => DropdownMenuItem(
                        value: f.id,
                        child: Text(f.name),
                      ),
                    )
                    .toList(),
                onChanged: _saving
                    ? null
                    : (v) => setState(() => _selectedFolderId = v),
              );
            },
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _canSave ? _save : null,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _delete,
            child: Text(
              'Delete bookmark',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
