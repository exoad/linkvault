import 'package:flutter/material.dart';

import '../../theme/theme_controller.dart';
import '../../widgets/linkvault_ambient_background.dart';
import 'appearance_section.dart';
import 'update_section.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.themeController});

  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: LinkvaultAmbientBackground(
        intensity: 0.65,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.paddingOf(context).top + kToolbarHeight + 8,
            16,
            16 + padding.bottom,
          ),
          children: [
            const UpdateSection(),
            const SizedBox(height: 24),
            AppearanceSection(themeController: themeController),
          ],
        ),
      ),
    );
  }
}
