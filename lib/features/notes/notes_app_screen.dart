import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../animations/app_page_route.dart';
import '../../animations/interaction_motion.dart';
import '../../animations/list_entrance.dart';
import '../../app_scope.dart';
import '../../hub/modules/notes_hub_module.dart';
import '../../models/note.dart';
import '../../theme/hub_app_colors.dart';
import '../../theme/linkvault_design.dart';
import '../../theme/linkvault_typography.dart';
import '../../widgets/linkvault_animated_ambient.dart';
import '../../widgets/hub_app_back_button.dart';
import '../../widgets/linkvault_ambient_background.dart';
import '../../widgets/linkvault_icon_chip.dart';
import '../../widgets/linkvault_surface.dart';
import '../../widgets/note_list_tile.dart';
import 'note_editor_screen.dart';

/// Notes hub app — local notes on this device.
class NotesAppScreen extends StatelessWidget {
  const NotesAppScreen({super.key});

  static const _app = NotesHubModule.appDefinition;

  Future<void> _openEditor(BuildContext context, {NoteModel? note}) async {
    await Navigator.push<void>(
      context,
      AppPageRoute(child: NoteEditorScreen(note: note)),
    );
  }

  Future<void> _deleteNote(BuildContext context, NoteModel note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete note?'),
        content: Text('“${note.displayTitle}” will be removed from this device.'),
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
    if (confirmed != true || !context.mounted) return;
    await AppScope.notesOf(context).deleteNote(note.id);
  }

  @override
  Widget build(BuildContext context) {
    final notes = AppScope.notesOf(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final phase = AmbientMotionScope.maybeOf(context);

    Widget appBarTitle(Color iconColor) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(PhosphorIcons.note, color: iconColor, size: 22),
            const SizedBox(width: 8),
            const Text('Notes'),
          ],
        );

    final title = phase != null
        ? AnimatedBuilder(
            animation: phase,
            builder: (context, _) => appBarTitle(
              HubAppColors.palette(_app, phase.value).primary,
            ),
          )
        : appBarTitle(_app.seedPrimary);

    return LinkvaultAmbientScaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: const HubAppBackButton(),
        title: title,
        actions: [
          AliveIconButton(
            tooltip: 'New note',
            icon: PhosphorIcon(PhosphorIcons.plus),
            onPressed: () => _openEditor(context),
          ),
        ],
      ),
      body: StreamBuilder<List<NoteModel>>(
        stream: notes.watchNotes(),
        builder: (context, snapshot) {
          final items = snapshot.data;
          final topPad =
              MediaQuery.paddingOf(context).top + kToolbarHeight + 8;

          if (items == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (items.isEmpty) {
            return _EmptyNotes(
              topPadding: topPad,
              onCreate: () => _openEditor(context),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.fromLTRB(16, topPad, 16, 88 + bottomInset),
            itemCount: items.length + 1,
            separatorBuilder: (_, index) =>
                SizedBox(height: index == 0 ? 12 : 10),
            itemBuilder: (context, index) {
              if (index == 0) {
                final label =
                    items.length == 1 ? '1 note' : '${items.length} notes';
                return Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ).listEntrance(context, index: 0);
              }

              final note = items[index - 1];
              return NoteListTile(
                note: note,
                app: _app,
                onTap: () => _openEditor(context, note: note),
                onDelete: () => _deleteNote(context, note),
              ).listEntrance(context, index: index);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context),
        icon: PhosphorIcon(PhosphorIcons.notePencil),
        label: const Text('New note'),
      ).aliveBreathe(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _EmptyNotes extends StatelessWidget {
  const _EmptyNotes({required this.topPadding, required this.onCreate});

  final double topPadding;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final phase = AmbientMotionScope.maybeOf(context);
    final colors = phase != null
        ? HubAppColors.palette(NotesAppScreen._app, phase.value)
        : null;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, topPadding, 16, 24),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: LinkvaultSurface(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 32,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinkvaultIconChip(
                      color: colors?.primary ?? scheme.onSurface,
                      dimension: 76,
                      child: PhosphorIcon(
                        PhosphorIcons.note,
                        size: 34,
                        color: colors?.primary ?? scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: LinkvaultDesign.spaceXl),
                    Text(
                      'No notes yet',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: LinkvaultDesign.spaceSm),
                    Text(
                      'Capture ideas, lists, and reminders — stored only on this device.',
                      textAlign: TextAlign.center,
                      style: LinkvaultTypography.hubSubtitle(scheme),
                    ),
                  ],
                ),
              ),
            ),
          ),
          FilledButton.icon(
            onPressed: onCreate,
            icon: PhosphorIcon(PhosphorIcons.notePencil),
            label: const Text('Create note'),
          ),
        ],
      ),
    );
  }
}
