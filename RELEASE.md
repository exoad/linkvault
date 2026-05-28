# Releasing Linkvault

1. Bump version in `pubspec.yaml` (`version: x.y.z+build`, e.g. `1.0.1+2`).
2. Commit on `main`.
3. Tag and push:

```bash
git tag v1.0.1
git push origin main
git push origin v1.0.1
```

GitHub Actions builds the release APK, writes `linkvault-update.json` + checksums, and publishes a GitHub Release.

The tag **must** match the pubspec version name (`v1.0.1` ↔ `1.0.1`).

## Signing

CI and local release builds currently use the **debug keystore** (personal sideload only). In-app updates require the same signing key across versions. For wider distribution, add a release keystore and GitHub Actions secrets (`ANDROID_KEYSTORE_BASE64`, passwords, alias).
