# Security

## What stays on your device

Bookmark URLs, titles, folder PIN hashes, and the SQLite database are stored **only on the device**. Nothing is uploaded to GitHub or any backend by this app.

In-app and GitHub Release updates are intended to **preserve** local data; see [DATA.md](DATA.md).

## What is public in this repo

- Source code ([GPL-3.0](LICENSE))
- GitHub username `exoad` and repo name `linkvault` (used for release updates)
- Release APKs and `linkvault-update.json` checksum manifests

There are **no API keys, tokens, or signing keystores** in the repository.

## Never commit

- `android/local.properties`, `key.properties`, `*.jks`, `*.keystore`
- `.env` files or any `ghp_` / `gho_` tokens
- Personal databases or exported bookmarks

CI runs [Gitleaks](https://github.com/gitleaks/gitleaks) on pushes and pull requests to catch accidental secrets.

## If you leak a secret

Revoke the credential immediately (GitHub → Settings → Developer settings). Removing it from git history requires a force-push or GitHub secret-removal support; do not rely on a normal delete commit alone.
