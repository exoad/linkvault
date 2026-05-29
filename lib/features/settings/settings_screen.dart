import 'package:flutter/material.dart';

import '../../ui/linkvault_ui.dart';
import 'appearance_section.dart';
import 'update_section.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);

    return LinkvaultAmbientScaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          LinkvaultDesign.spaceLg,
          MediaQuery.paddingOf(context).top + kToolbarHeight + LinkvaultDesign.spaceSm,
          LinkvaultDesign.spaceLg,
          LinkvaultDesign.spaceLg + padding.bottom,
        ),
        children: [
          const UpdateSection().listEntrance(context, index: 0),
          const SizedBox(height: 24),
          const AppearanceSection().listEntrance(context, index: 1),
        ],
      ),
    );
  }
}
