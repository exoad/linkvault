# Releasing Linkvault

1. Bump version in `pubspec.yaml` (`version: x.y.z+build`, e.g. `1.0.5+6`).
2. Commit on `main`.
3. Tag and push:

```bash
git tag v1.0.5
git push origin main
git push origin v1.0.5
```

GitHub Actions builds the release APK, writes `linkvault-update.json` + checksums, and publishes a GitHub Release.

The tag **must** match the pubspec version name (`v1.0.5` ↔ `1.0.5`).

## Data across updates

Installing a release APK over an existing install **keeps** folders, bookmarks, and settings when both builds use the same signing key (they do — see below).

When changing the database schema, bump `schemaVersion` in `app_database.dart`, add a step in `database_migrations.dart`, and extend `test/database_migration_test.dart`.

## Signing

All **release** APKs (CI and `flutter build apk --release`) use the shared in-repo key:

- `android/linkvault-release.jks`
- `android/key.properties`

No GitHub secrets or local setup. This is a personal app; the key is in git so every release matches for in-app updates.

`flutter run` debug builds use a different key — use **Settings → Check for updates** or a GitHub APK for day-to-day installs.

If you previously installed a build signed another way (old CI debug or a local debug APK), uninstall once and install the latest release; after that, updates work in-app again.
