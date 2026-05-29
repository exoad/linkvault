# Data persistence

Linkvault is designed so **normal app updates keep your data**.

## What is stored locally

| Store | Contents |
|-------|----------|
| SQLite (`linkvault` database) | Folders, bookmarks, notes, chat sessions/messages, optional folder PIN hashes |
| SharedPreferences | Theme mode, accent color, layout preferences, chat inference backend (CPU/GPU), optional Hugging Face token |
| App documents storage | Downloaded on-device LLM weights (`files/models/`, ~2.6 GB Gemma 4 E2B `.litertlm`; not in the APK) |

Nothing is synced to a server.

Shared content (system share sheet, selected-text action, launcher shortcuts) is delivered as a **transient intent** and is not persisted until you save it as a link or note. See [HUB_MODULES.md](HUB_MODULES.md) for the intent-routing contract.

## APK updates (GitHub Releases / in-app install)

Installing a newer APK **over** an existing install **does not erase** app data when:

- Package name stays `net.exoad.linkvault`
- The new APK is signed with the **same key** as the installed build (debug or release keystore you have always used)

Android replaces the app binary and leaves the app’s private storage (database + preferences) in place.

**Data is removed only if you:**

- Uninstall the app
- Clear storage in system settings (“Clear data”)
- Install a build signed with a **different** key (e.g. an old debug install vs a GitHub release). Use release APKs from GitHub for in-app updates; one reinstall fixes a mismatch.

## Database schema changes

Schema version is defined in [`lib/data/app_database.dart`](lib/data/app_database.dart). Upgrades use **additive migrations** only (new columns/tables) in [`lib/data/database_migrations.dart`](lib/data/database_migrations.dart).

We do **not** drop or recreate the database on version bumps. Existing folders and bookmarks are migrated in place.

Schema **v3** adds the `notes` table for the Notes app.

Schema **v4** adds `chat_sessions` and `chat_messages` for the Chat app (local conversation history only; inference runs on-device).

**Automatic migration:** On launch, Drift compares the on-disk `user_version` to `AppDatabase.schemaVersion`. If the app is newer (e.g. installed v1.0.5 on schema 2, updated to v1.0.6 on schema 3), `onUpgrade` runs `DatabaseMigrations.migrateStepwise` (v2 → v3, etc.) before any query. No user action required.

When adding schema version `4+`:

1. Bump `DatabaseMigrations.targetSchemaVersion` and `AppDatabase.schemaVersion` (same value).
2. Register `DatabaseMigrations.steps[4] = _toV4`.
3. Extend `test/database_migration_test.dart` and `test/schema_version_test.dart`.

## After updating

Open the app as usual. Folders, links, and settings should appear as before. If something looks wrong after an update, file an issue with the versions you moved between — that indicates a migration bug to fix, not expected behavior.
