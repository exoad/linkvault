import 'package:flutter/material.dart';

import '../platform/app_api.g.dart';

/// Visual identity for a hub app tile (living colors use [phaseOffset]).
@immutable
class HubAppDefinition {
  const HubAppDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.seedPrimary,
    required this.seedSecondary,
    required this.phaseOffset,
  });

  /// Stable string id — use in routes, prefs, and module registry.
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color seedPrimary;
  final Color seedSecondary;

  /// Offsets ambient color cycle so apps feel distinct on the hub.
  final double phaseOffset;
}

enum HubModuleStatus {
  /// Shown on the hub grid and can be opened.
  available,

  /// Shown as a teaser below the grid (not openable yet).
  comingSoon,
}

/// Contract for a hub “app”. Register implementations in [HubRegistry].
abstract class HubModule {
  HubAppDefinition get definition;
  HubModuleStatus get status;

  /// Opens the app (push route, sheet, etc.).
  void open(BuildContext context);

  /// Short stat for the hub tile, e.g. `3 links` or `Coming soon`.
  Stream<String> watchStatLabel(BuildContext context);
}

/// Optional capability: a [HubModule] that can act on an external intent
/// (share target, process-text, or launcher shortcut).
///
/// Implement alongside [HubModule] and the [IntentRouter] will route matching
/// intents here. New apps opt in simply by adding `implements IntentAware`.
mixin IntentAware {
  /// Whether this module wants to handle [intent].
  bool canHandle(IncomingIntent intent);

  /// Presents this module's capture UI for [intent] (sheet, editor, etc.).
  Future<void> handleIntent(BuildContext context, IncomingIntent intent);
}
