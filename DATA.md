# Data persistence

Linkvault is designed so **normal app updates keep your data**.

## What is stored locally

| Store | Contents |
|-------|----------|
| SQLite (`linkvault` database) | Folders, bookmarks, optional folder PIN hashes |
| SharedPreferences | Theme mode, accent color, layout preferences |

Nothing is synced to a server.

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

When adding schema version `3+`, add a `_toV3` step in `database_migrations.dart` and a test in `test/database_migration_test.dart`.

## After updating

Open the app as usual. Folders, links, and settings should appear as before. If something looks wrong after an update, file an issue with the versions you moved between — that indicates a migration bug to fix, not expected behavior.
