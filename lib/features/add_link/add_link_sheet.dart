import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../animations/animated_sheet.dart';
import '../../app_scope.dart';
import '../../models/folder.dart';
import '../../services/folder_preferences.dart';
import '../../services/url_normalizer.dart';
import '../../theme/app_motion.dart';
import '../../widgets/phosphor_app_icon.dart';

Future<void> showAddLinkSheet(
  BuildContext context, {
  String? initialFolderId,
}) {
  return showAppBottomSheet<void>(
    context: context,
    builder: (context) => AddLinkSheet(initialFolderId: initialFolderId),
  );
}

class AddLinkSheet extends StatefulWidget {
  const AddLinkSheet({super.key, this.initialFolderId});

  final String? initialFolderId;

  @override
  State<AddLinkSheet> createState() => _AddLinkSheetState();
}

class _AddLinkSheetState extends State<AddLinkSheet> {
  final _controller = TextEditingController();
  final _folderPrefs = FolderPreferences();
  String? _selectedFolderId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedFolderId = widget.initialFolderId;
    _loadLastFolder();
  }

  Future<void> _loadLastFolder() async {
    if (widget.initialFolderId != null) return;
    final lastId = await _folderPrefs.getLastFolderId();
    if (lastId != null && mounted) {
      setState(() => _selectedFolderId ??= lastId);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSave =>
      !_saving && UrlNormalizer.isValid(_controller.text);

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text != null && text.isNotEmpty) {
      _controller.text = text;
      setState(() {});
    }
  }

  Future<void> _save() async {
    if (!_canSave || _selectedFolderId == null) return;
    setState(() => _saving = true);

    try {
      final repo = AppScope.of(context);
      await repo.addBookmark(
        rawUrl: _controller.text,
        folderId: _selectedFolderId!,
      );
      await _folderPrefs.setLastFolderId(_selectedFolderId!);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save link: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final repo = AppScope.of(context);
    final motion = motionEnabled(context);

    Widget saveButton = FilledButton(
      onPressed: _canSave ? _save : null,
      child: _saving
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('Save'),
    );

    if (motion) {
      saveButton = saveButton
          .animate(target: _canSave ? 1 : 0)
          .scale(
            begin: const Offset(0.98, 0.98),
            end: const Offset(1, 1),
            duration: AppMotion.fast,
          );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Paste link', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Semantics(
            label: 'URL to save',
            textField: true,
            child: TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.url,
              autofillHints: const [AutofillHints.url],
              textInputAction: TextInputAction.done,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'https://example.com',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) {
                if (_canSave) _save();
              },
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pasteFromClipboard,
            icon: PhosphorIcon(PhosphorIcons.clipboard),
            label: const Text('Paste from clipboard'),
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<FolderModel>>(
            stream: repo.watchFolders(),
            builder: (context, snapshot) {
              final folders = snapshot.data
                      ?.where(repo.canAccessFolder)
                      .toList() ??
                  [];
              if (folders.isEmpty) {
                return const LinearProgressIndicator();
              }

              final unfiledId = repo.unfiledFolderId;
              _selectedFolderId ??= widget.initialFolderId ?? unfiledId;
              if (!folders.any((f) => f.id == _selectedFolderId)) {
                _selectedFolderId = unfiledId;
              }

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
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor:
                                  f.color.withValues(alpha: 0.2),
                              child: PhosphorAppIcon(
                                f.iconName,
                                size: 16,
                                color: f.color,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(f.name)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _selectedFolderId = value),
              );
            },
          ),
          const SizedBox(height: 16),
          saveButton,
        ],
      ),
    );
  }
}
