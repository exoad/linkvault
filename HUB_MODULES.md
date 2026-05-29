# Adding a hub app

Hub apps are modular. Each app is a class that implements [`HubModule`](lib/hub/hub_module.dart) and is listed in [`HubRegistry.modules`](lib/hub/hub_registry.dart).

## Checklist for a new app

1. **Implement `HubModule`** (see `lib/hub/modules/links_hub_module.dart`):
   - `definition` — id, name, description, icon, seed colors, `phaseOffset`
   - `status` — `available` (launcher tile) or `comingSoon` (teaser strip)
   - `open(context)` — navigate to your app root screen
   - `watchStatLabel(context)` — stream for the hub tile subtitle

2. **Register** the module in `HubRegistry.modules` (order = display order).

3. **Build the app UI** under `lib/features/<your_app>/`.

4. **Persistence** (if needed):
   - Bump `AppDatabase.schemaVersion`
   - Set `DatabaseMigrations.targetSchemaVersion` to the same value
   - Add `DatabaseMigrations.steps[N] = _toVN` for the new version
   - Add a test in `test/database_migration_test.dart`

   Migrations run **automatically** on app launch when the on-disk DB is older than `schemaVersion`.

5. **Wire dependencies** in `main.dart` / `AppScope` if the app needs a repository.

## Optional: handle external intents (share / shortcuts)

A module can react to inbound Android intents (the system share sheet, the
selected-text "Linkvault" action, or a launcher shortcut) by also mixing in
[`IntentAware`](lib/hub/hub_module.dart):

```dart
final class MyHubModule implements HubModule, IntentAware {
  // ...HubModule members...

  @override
  bool canHandle(IncomingIntent intent) => intent.kind == IntentKind.shareText;

  @override
  Future<void> handleIntent(BuildContext context, IncomingIntent intent) {
    // Present this app's capture UI, seeded with intent.text.
  }
}
```

- `IntentRouter` ([lib/services/intent_router.dart](lib/services/intent_router.dart)) dispatches each intent to the first registered `IntentAware` module that returns `true` from `canHandle`. A matching `IncomingIntent.targetModuleId` (set by launcher shortcuts) is preferred.
- The Kotlin side ([`IntentReader`](android/app/src/main/kotlin/net/exoad/linkvault/IntentReader.kt)) normalizes raw `Intent`s into an `IncomingIntent` (`saveLink` / `newNote` / `shareText`). Cold starts are pulled via `IntentHostApi.getInitialIntent`; warm starts are pushed via `FlutterIntentApi.onIntent`. Both are type-safe Pigeon APIs generated from [pigeons/app_api.dart](pigeons/app_api.dart).
- To add a launcher shortcut for your app, add a `<shortcut>` with a unique action to [res/xml/shortcuts.xml](android/app/src/main/res/xml/shortcuts.xml) and map that action in `IntentReader.fromIntent`.

Regenerate the platform bridge after editing the Pigeon schema:

```bash
dart run pigeon --input pigeons/app_api.dart
```

## Example: flip a teaser to available

Change `ThoughtsHubModule.status` to `HubModuleStatus.available`, implement `open()`, and add a `features/thoughts/` screen.

## App ids

Use stable lowercase string ids (`links`, `notes`, `chat`, `thoughts`). They are used for definitions, as the `targetModuleId` hint for intent routing, and can be used for deep links or prefs later.

## Chat app (v1.1)

- Module: [`lib/hub/modules/chat_hub_module.dart`](lib/hub/modules/chat_hub_module.dart)
- UI: [`lib/features/chat/`](lib/features/chat/)
- AI layer: [`lib/ai/`](lib/ai/) via `flutter_gemma` (Gemma 3n E2B weights downloaded on first use)
- Shell route: register `ChatHubModule.id` in [`lib/shell/app_shell.dart`](lib/shell/app_shell.dart)
- Schema v4 chat tables; wire `ChatRepository` + `ChatService` in `main.dart` / `AppScope`
