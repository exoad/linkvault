import 'package:flutter_test/flutter_test.dart';
import 'package:linkvault/hub/hub_module.dart';
import 'package:linkvault/hub/hub_registry.dart';
import 'package:linkvault/hub/modules/links_hub_module.dart';
import 'package:linkvault/hub/modules/notes_hub_module.dart';
import 'package:linkvault/hub/modules/thoughts_hub_module.dart';

void main() {
  test('launcher excludes coming-soon modules', () {
    final launcherIds =
        HubRegistry.launcher.map((m) => m.definition.id).toList();
    expect(launcherIds, containsAll([LinksHubModule.id, NotesHubModule.id]));
    expect(launcherIds, isNot(contains(ThoughtsHubModule.id)));
  });

  test('coming-soon modules are registered as teasers', () {
    final teaserIds =
        HubRegistry.comingSoon.map((m) => m.definition.id).toList();
    expect(teaserIds, contains(ThoughtsHubModule.id));
  });

  test('module ids are unique', () {
    final ids = HubRegistry.modules.map((m) => m.definition.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('findById returns registered modules', () {
    expect(HubRegistry.findById(LinksHubModule.id), isA<HubModule>());
    expect(HubRegistry.findById('unknown'), isNull);
  });
}
