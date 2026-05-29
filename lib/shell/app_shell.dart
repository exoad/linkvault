import 'package:flutter/material.dart';

import '../features/hub/hub_screen.dart';
import '../features/links/links_app_screen.dart';
import '../features/notes/notes_app_screen.dart';
import '../hub/modules/links_hub_module.dart';
import '../hub/modules/notes_hub_module.dart';
import '../theme/app_motion.dart';

/// Exposes hub ↔ app switching without pushing a full-screen route (keeps the
/// global ambient backdrop continuous).
class AppShellScope extends InheritedWidget {
  const AppShellScope({
    super.key,
    required this.activeModuleId,
    required this.openModule,
    required this.closeModule,
    required super.child,
  });

  final String? activeModuleId;
  final void Function(String moduleId) openModule;
  final VoidCallback closeModule;

  static AppShellScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'No AppShellScope found in context');
    return scope!;
  }

  static AppShellScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppShellScope>();
  }

  @override
  bool updateShouldNotify(AppShellScope oldWidget) =>
      activeModuleId != oldWidget.activeModuleId;
}

/// Root shell: hub launcher and hub apps share one navigator stack entry so the
/// ambient layer never restarts when opening Links or Notes.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  String? _moduleId;

  void _openModule(String id) {
    if (_moduleId == id) return;
    setState(() => _moduleId = id);
  }

  void _closeModule() {
    if (_moduleId == null) return;
    setState(() => _moduleId = null);
  }

  Widget _screenFor(String id) {
    return switch (id) {
      LinksHubModule.id => const LinksAppScreen(),
      NotesHubModule.id => const NotesAppScreen(),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final content = _moduleId == null
        ? const HubScreen()
        : _screenFor(_moduleId!);

    return AppShellScope(
      activeModuleId: _moduleId,
      openModule: _openModule,
      closeModule: _closeModule,
      child: AnimatedSwitcher(
        duration: AppMotion.slow,
        switchInCurve: AppMotion.emphasized,
        switchOutCurve: AppMotion.emphasized,
        transitionBuilder: (child, animation) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: AppMotion.emphasized,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.08, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          );
        },
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(
            fit: StackFit.expand,
            children: [
              ...previousChildren,
              ?currentChild,
            ],
          );
        },
        child: KeyedSubtree(
          key: ValueKey<String?>(_moduleId),
          child: content,
        ),
      ),
    );
  }
}
