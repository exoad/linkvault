import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../app_scope.dart';
import '../../shell/app_shell.dart';
import '../../features/add_link/add_link_sheet.dart';
import '../../platform/app_api.g.dart';
import '../hub_module.dart';

/// Links hub app — folders and saved URLs.
final class LinksHubModule implements HubModule, IntentAware {
  const LinksHubModule();

  static const id = 'links';

  static const appDefinition = HubAppDefinition(
    id: id,
    name: 'Links',
    description: 'Saved URLs',
    icon: PhosphorIcons.link,
    seedPrimary: Color(0xFF4DA8FF),
    seedSecondary: Color(0xFF38BDF8),
    phaseOffset: 0.0,
  );

  @override
  HubAppDefinition get definition => appDefinition;

  @override
  HubModuleStatus get status => HubModuleStatus.available;

  @override
  void open(BuildContext context) {
    AppShellScope.of(context).openModule(id);
  }

  @override
  Stream<String> watchStatLabel(BuildContext context) {
    return AppScope.of(context).watchFolders().map((folders) {
      final count =
          folders.fold<int>(0, (sum, folder) => sum + folder.bookmarkCount);
      return count == 1 ? '1 link' : '$count links';
    });
  }

  @override
  bool canHandle(IncomingIntent intent) => intent.kind == IntentKind.saveLink;

  @override
  Future<void> handleIntent(BuildContext context, IncomingIntent intent) {
    // Present the Add Link sheet (URL prefilled when shared); the user picks
    // the folder and confirms.
    return showAddLinkSheet(context, initialText: intent.text);
  }
}
