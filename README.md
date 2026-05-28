<div align="center">

<img src="assets/branding/app_icon_foreground.png" alt="" width="88" height="88" />

# linkvault

**Personal Android hub** — Links and Notes apps on your home screen; Thoughts coming later.

[![License: GPL v3](https://img.shields.io/github/license/exoad/linkvault?style=flat-square)](LICENSE)
[![Release](https://img.shields.io/github/v/release/exoad/linkvault?style=flat-square)](https://github.com/exoad/linkvault/releases/latest)
[![CI](https://img.shields.io/github/actions/workflow/status/exoad/linkvault/ci.yml?branch=main&style=flat-square&label=CI)](https://github.com/exoad/linkvault/actions/workflows/ci.yml)
[![Flutter](https://img.shields.io/badge/Flutter-stable-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?style=flat-square&logo=android&logoColor=white)](https://www.android.com)

[Download APK](https://github.com/exoad/linkvault/releases/latest) · [Releases](https://github.com/exoad/linkvault/releases) · [Security](SECURITY.md) · [How to release](RELEASE.md)

</div>

---

Not a public product — built for personal use. Source is public under [GPL-3.0](LICENSE).

## Features

| | |
|---|---|
| **Your hub** | App launcher with living color tiles (Links, Notes) |
| **Links app** | Folders, paste-to-save, optional folder PIN |
| **Notes app** | Local notes on device — separate from future Thoughts |
| **Offline folders** | Organize links; mandatory **Unfiled** inbox |
| **Share to save** | Share a URL/text or select text in any app to save into Links or Notes |
| **Launcher shortcuts** | Long-press the app icon for **Paste link** / **New note** |
| **Paste to save** | Add links from clipboard with metadata fetch |
| **Folder PIN** | Optional 4-digit lock per folder |
| **Expressive UI** | Large type, ambient gradients (background only), list/grid layouts |
| **Material 3** | System / light / dark, dynamic color on Android 12+ |
| **On-demand updates** | **Settings → Check for updates** (same signing key on every GitHub release) |

## Quick start

```bash
git clone https://github.com/exoad/linkvault.git
cd linkvault
flutter pub get
flutter run
```

Prefer a binary? Grab the latest **`linkvault-*.apk`** from [Releases](https://github.com/exoad/linkvault/releases/latest), or open the app → **Settings** → **Check for updates**.

## Develop

```bash
flutter analyze
flutter test
flutter build apk --release
```

Tagging and CI releases: see [RELEASE.md](RELEASE.md).

## License

This project is licensed under the [GNU General Public License v3.0](LICENSE) (full text from the [FSF](https://www.gnu.org/licenses/gpl-3.0.txt)).
