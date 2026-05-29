import 'package:flutter/material.dart';

import '../../animations/list_entrance.dart';
import 'appearance_section.dart';
import 'update_section.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          MediaQuery.paddingOf(context).top + kToolbarHeight + 8,
          16,
          16 + padding.bottom,
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
