import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkvault/hub/modules/links_hub_module.dart';
import 'package:linkvault/hub/modules/notes_hub_module.dart';
import 'package:linkvault/platform/app_api.g.dart';
import 'package:linkvault/services/intent_router.dart';

void main() {
  final router = IntentRouter(navigatorKey: GlobalKey<NavigatorState>());

  group('IntentRouter.resolveHandler', () {
    test('saveLink routes to the Links module', () {
      final handler = router.resolveHandler(
        IncomingIntent(kind: IntentKind.saveLink, text: 'https://a.com'),
      );
      expect(handler, isA<LinksHubModule>());
    });

    test('newNote routes to the Notes module', () {
      final handler = router.resolveHandler(
        IncomingIntent(kind: IntentKind.newNote),
      );
      expect(handler, isA<NotesHubModule>());
    });

    test('shareText routes to the Notes module', () {
      final handler = router.resolveHandler(
        IncomingIntent(kind: IntentKind.shareText, text: 'a thought'),
      );
      expect(handler, isA<NotesHubModule>());
    });

    test('targetModuleId hint is honored when it can handle the intent', () {
      final handler = router.resolveHandler(
        IncomingIntent(
          kind: IntentKind.saveLink,
          text: 'https://a.com',
          targetModuleId: 'links',
        ),
      );
      expect(handler, isA<LinksHubModule>());
    });

    test('an unsupported hint falls back to capability matching', () {
      final handler = router.resolveHandler(
        IncomingIntent(
          kind: IntentKind.newNote,
          targetModuleId: 'links',
        ),
      );
      expect(handler, isA<NotesHubModule>());
    });
  });
}
