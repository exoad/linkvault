import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../shell/app_shell.dart';
import '../hub_module.dart';

/// Local AI chat hub app.
final class ChatHubModule implements HubModule {
  const ChatHubModule();

  static const id = 'chat';

  static const appDefinition = HubAppDefinition(
    id: id,
    name: 'Chat',
    description: 'On-device AI with tools',
    icon: PhosphorIcons.chatCircle,
    seedPrimary: Color(0xFF34D399),
    seedSecondary: Color(0xFF60A5FA),
    phaseOffset: 0.52,
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
  Stream<String> watchStatLabel(BuildContext context) async* {
    yield 'Local AI';
  }
}
