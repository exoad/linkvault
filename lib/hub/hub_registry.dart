import 'hub_module.dart';
import 'modules/chat_hub_module.dart';
import 'modules/links_hub_module.dart';
import 'modules/notes_hub_module.dart';
import 'modules/thoughts_hub_module.dart';

/// Central registry of hub apps. **Add new apps here** — see [HUB_MODULES.md].
abstract final class HubRegistry {
  /// All registered modules in display order.
  static const modules = <HubModule>[
    LinksHubModule(),
    NotesHubModule(),
    ChatHubModule(),
    ThoughtsHubModule(),
  ];

  /// Apps shown on the hub launcher grid.
  static List<HubModule> get launcher =>
      modules.where((m) => m.status == HubModuleStatus.available).toList();

  /// Teasers below the grid (not openable yet).
  static List<HubModule> get comingSoon =>
      modules.where((m) => m.status == HubModuleStatus.comingSoon).toList();

  static HubModule? findById(String id) {
    for (final module in modules) {
      if (module.definition.id == id) return module;
    }
    return null;
  }

  static HubAppDefinition definitionFor(String id) {
    final module = findById(id);
    if (module == null) {
      throw ArgumentError('Unknown hub app id: $id');
    }
    return module.definition;
  }
}
