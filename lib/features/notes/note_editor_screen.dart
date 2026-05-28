import 'package:flutter/material.dart';
import '../../app_scope.dart';
import '../../data/note_repository.dart';
import '../../hub/modules/notes_hub_module.dart';
import '../../models/note.dart';
import '../../theme/hub_app_colors.dart';
import '../../theme/linkvault_accent.dart';
import '../../widgets/linkvault_animated_ambient.dart';
import '../../widgets/linkvault_ambient_background.dart';

class NoteEditorScreen extends StatefulWidget {
  const NoteEditorScreen({super.key, this.note});

  final NoteModel? note;

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  static const _app = NotesHubModule.appDefinition;

  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  bool _saving = false;
  bool _dirty = false;

  bool get _isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _bodyController = TextEditingController(text: widget.note?.body ?? '');
    _titleController.addListener(_markDirty);
    _bodyController.addListener(_markDirty);
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  NoteUpsert get _upsert => NoteUpsert(
        title: _titleController.text,
        body: _bodyController.text,
      );

  Future<bool> _save() async {
    if (_saving) return false;
    setState(() => _saving = true);

    try {
      final repo = AppScope.notesOf(context);
      if (_isEditing) {
        await repo.updateNote(widget.note!.id, _upsert);
      } else {
        await repo.createNote(_upsert);
      }
      if (mounted) setState(() => _dirty = false);
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save note: $e')),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _handleBack() async {
    if (!_dirty) {
      if (mounted) Navigator.pop(context);
      return;
    }
    final saved = await _save();
    if (saved && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).extension<LinkvaultAccent>();
    final phase = AmbientMotionScope.maybeOf(context);
    final appColor = accent != null && phase != null
        ? HubAppColors.palette(accent, _app, phase.value).primary
        : _app.seedPrimary;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleBack();
      },
      child: LinkvaultAmbientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            leading: BackButton(onPressed: _handleBack),
            title: Text(_isEditing ? 'Edit note' : 'New note'),
            actions: [
              TextButton(
                onPressed: _saving
                    ? null
                    : () async {
                        final ok = await _save();
                        if (!context.mounted) return;
                        if (ok) Navigator.pop(context);
                      },
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              TextField(
                controller: _titleController,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                decoration: InputDecoration(
                  hintText: 'Title',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: appColor.withValues(alpha: 0.5)),
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _bodyController,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.5,
                    ),
                decoration: const InputDecoration(
                  hintText: 'Start writing…',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                keyboardType: TextInputType.multiline,
                maxLines: null,
                minLines: 12,
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
