import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../animations/app_page_route.dart';
import '../../app_scope.dart';
import '../../features/notes/notes_app_screen.dart';
import '../hub_module.dart';

/// Notes hub app — local notes on this device.
final class NotesHubModule implements HubModule {
  const NotesHubModule();

  static const id = 'notes';

  static const appDefinition = HubAppDefinition(
    id: id,
    name: 'Notes',
    description: 'Local notes',
    icon: PhosphorIcons.note,
    seedPrimary: Color(0xFFFBBF24),
    seedSecondary: Color(0xFFA78BFA),
    phaseOffset: 0.38,
  );

  @override
  HubAppDefinition get definition => appDefinition;

  @override
  HubModuleStatus get status => HubModuleStatus.available;

  @override
  void open(BuildContext context) {
    Navigator.push<void>(
      context,
      AppPageRoute(child: const NotesAppScreen()),
    );
  }

  @override
  Stream<String> watchStatLabel(BuildContext context) {
    return AppScope.notesOf(context).watchNoteCount().map((count) {
      return count == 1 ? '1 note' : '$count notes';
    });
  }
}
