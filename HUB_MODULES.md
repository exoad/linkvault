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

## Example: flip a teaser to available

Change `ThoughtsHubModule.status` to `HubModuleStatus.available`, implement `open()`, and add a `features/thoughts/` screen.

## App ids

Use stable lowercase string ids (`links`, `notes`, `thoughts`). They are used for definitions and can be used for deep links or prefs later.
