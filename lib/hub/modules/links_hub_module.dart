import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../animations/app_page_route.dart';
import '../../app_scope.dart';
import '../../features/links/links_app_screen.dart';
import '../hub_module.dart';

/// Links hub app — folders and saved URLs.
final class LinksHubModule implements HubModule {
  const LinksHubModule();

  static const id = 'links';

  static const appDefinition = HubAppDefinition(
    id: id,
    name: 'Links',
    description: 'Folders and saved URLs',
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
    Navigator.push<void>(
      context,
      AppPageRoute(child: const LinksAppScreen()),
    );
  }

  @override
  Stream<String> watchStatLabel(BuildContext context) {
    return AppScope.of(context).watchFolders().map((folders) {
      final count =
          folders.fold<int>(0, (sum, folder) => sum + folder.bookmarkCount);
      return count == 1 ? '1 link' : '$count links';
    });
  }
}
