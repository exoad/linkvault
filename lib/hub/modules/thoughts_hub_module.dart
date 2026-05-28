import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../hub_module.dart';

/// Future Thoughts app — teaser only (separate from Notes).
final class ThoughtsHubModule implements HubModule {
  const ThoughtsHubModule();

  static const id = 'thoughts';

  static const appDefinition = HubAppDefinition(
    id: id,
    name: 'Thoughts',
    description: 'Coming soon — a separate space from Notes',
    icon: PhosphorIcons.lightbulb,
    seedPrimary: Color(0xFF818CF8),
    seedSecondary: Color(0xFF22D3EE),
    phaseOffset: 0.62,
  );

  @override
  HubAppDefinition get definition => appDefinition;

  @override
  HubModuleStatus get status => HubModuleStatus.comingSoon;

  @override
  void open(BuildContext context) {
    // Not launchable until implemented.
  }

  @override
  Stream<String> watchStatLabel(BuildContext context) async* {
    yield 'Coming soon';
  }
}
