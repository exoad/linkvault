<div align="center">

<img src="assets/branding/app_icon.png" alt="" width="88" height="88" />

# linkvault

**A personal Android hub** — one launcher, several apps, everything on device.

[![License: GPL v3](https://img.shields.io/github/license/exoad/linkvault?style=flat-square)](LICENSE)
[![Release](https://img.shields.io/github/v/release/exoad/linkvault?style=flat-square)](https://github.com/exoad/linkvault/releases/latest)
[![CI](https://img.shields.io/github/actions/workflow/status/exoad/linkvault/ci.yml?branch=main&style=flat-square&label=CI)](https://github.com/exoad/linkvault/actions/workflows/ci.yml)
[![Flutter](https://img.shields.io/badge/Flutter-stable-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?style=flat-square&logo=android&logoColor=white)](https://www.android.com)

[Download APK](https://github.com/exoad/linkvault/releases/latest) · [Releases](https://github.com/exoad/linkvault/releases) · [Security](SECURITY.md) · [How to release](RELEASE.md)

</div>

---

Not a public product. Source is public under [GPL-3.0](LICENSE).

## Hub

**Links** · **Notes** · **Chat** · *Thoughts* (later)

Modular tiles on a shared ambient shell. Each app is its own module; the backdrop does not reset when you move between them.

## Stack

Flutter · Drift (SQLite) · Kotlin embedding · Pigeon host APIs · on-device inference (`flutter_gemma`) where Chat needs it.

Dark-only chrome. Black canvas, white mark, edge glow. Chromatic motion lives in the ambient layer and hub accents—not in base UI chrome.

## Quick start

```bash
git clone https://github.com/exoad/linkvault.git
cd linkvault
flutter pub get
flutter run
```

Binary installs: latest `linkvault-*.apk` on [Releases](https://github.com/exoad/linkvault/releases/latest), or **Settings → Check for updates** in an existing install (same signing key).

## Develop

```bash
flutter analyze
flutter test
flutter build apk --release
```

Hub apps, schema migrations, intents, and agent-oriented notes: [AGENTS.md](AGENTS.md).  
Releases and tagging: [RELEASE.md](RELEASE.md).  
Persistence policy: [DATA.md](DATA.md).

## License

[GNU General Public License v3.0](LICENSE) — [FSF text](https://www.gnu.org/licenses/gpl-3.0.txt).
