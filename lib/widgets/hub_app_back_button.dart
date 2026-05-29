import 'package:flutter/material.dart';

import '../shell/app_shell.dart';

/// Back control for hub apps opened inside [AppShell] (not a pushed route).
class HubAppBackButton extends StatelessWidget {
  const HubAppBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BackButton(
      onPressed: () => AppShellScope.of(context).closeModule(),
    );
  }
}
