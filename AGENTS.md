# Agent guide — linkvault

Instructions for automated and human contributors working in this repository. Read this before non-trivial changes; keep it accurate when architecture or workflows shift.

## Identity

| | |
|---|---|
| **Product** | Personal Android hub (`net.exoad.linkvault`) |
| **Stack** | Flutter (Dart 3.12+), Drift/SQLite, Kotlin, Pigeon |
| **Platform** | Android-first (no iOS target in tree) |
| **License** | GPL-3.0 |

Not a hosted service. Data stays on device unless the user explicitly uses a tool that calls the network (e.g. link metadata fetch, Chat web search).

## Repository scope

Work **only** in this repo (`linkvault`). Do not assume sibling repos (`app-src`, `drosk-net`, etc.) unless the user explicitly expands scope.

**Do not cut releases** (version bump, tag, push, GitHub Release) unless the user asks. Local commits are fine when requested.

## Architecture (mental model)

```
main.dart
  └── LinkvaultApp (MaterialApp + AmbientShell)
        └── AppScope (repositories, ChatService)
              └── AppShell (hub ↔ module swap, no full-screen hub push)
                    ├── HubScreen (launcher grid)
                    └── feature roots (Links / Notes / Chat …)

Android: MainActivity, IntentReader, InstallManager, SplashOrbitOverlay
Bridge: pigeons/app_api.dart → lib/platform/*.g.dart, android/.../AppApi.g.kt
```

### Hub modules

Each app is a [`HubModule`](lib/hub/hub_module.dart) registered in [`HubRegistry.modules`](lib/hub/hub_registry.dart).

| Id | Status | Entry |
|----|--------|--------|
| `links` | available | [`LinksHubModule`](lib/hub/modules/links_hub_module.dart) → `LinksAppScreen` |
| `notes` | available | [`NotesHubModule`](lib/hub/modules/notes_hub_module.dart) → `NotesAppScreen` |
| `chat` | available | [`ChatHubModule`](lib/hub/modules/chat_hub_module.dart) → `ChatAppScreen` |
| `thoughts` | coming soon | teaser only |

Opening a module uses [`AppShellScope.openModule`](lib/shell/app_shell.dart) so the global ambient background does not restart. Pushed routes (settings, editors, folders) use opaque [`AppPageRoute`](lib/animations/app_page_route.dart).

**Adding a hub app:** follow [HUB_MODULES.md](HUB_MODULES.md).

### Ambient UI

- [`AmbientShell`](lib/widgets/linkvault_ambient_background.dart) wraps the app in `MaterialApp.builder`.
- Feature scaffolds use [`LinkvaultAmbientScaffold`](lib/widgets/linkvault_ambient_background.dart) (transparent; glow shows through).
- Theme: dark-only, monochrome base — [`LinkvaultMonochrome`](lib/theme/linkvault_monochrome.dart). Accents cycle via [`AmbientLavaPalette`](lib/theme/ambient_lava_palette.dart).
- Chat uses additional AI glow widgets under [`lib/features/chat/widgets/`](lib/features/chat/widgets/).

### Data layer

- Single Drift DB: [`AppDatabase`](lib/data/app_database.dart).
- Schema version: `DatabaseMigrations.targetSchemaVersion` (currently **4** — includes `chat_sessions` / `chat_messages`).
- Migrations: additive only in [`database_migrations.dart`](lib/data/database_migrations.dart); never drop/recreate user tables in migrations.
- Policy and user-facing persistence notes: [DATA.md](DATA.md).

**Schema change checklist**

1. Add tables/columns in `app_database.dart`.
2. Bump `targetSchemaVersion` and register `steps[N]`.
3. Run `dart run build_runner build`.
4. Extend `test/database_migration_test.dart` and keep `test/schema_version_test.dart` green.

### Chat / on-device AI (Kotlin-native)

| Layer | Location |
|-------|----------|
| Pigeon API | [`pigeons/app_api.dart`](pigeons/app_api.dart) — `LlmHostApi`, `FlutterLlmApi` |
| Kotlin engine | [`android/.../llm/`](android/app/src/main/kotlin/net/exoad/linkvault/llm/) — LiteRT-LM + MediaPipe |
| Dart bridge | [`FlutterLlmBridge`](lib/ai/chat/flutter_llm_bridge.dart), [`NativeLlmRuntime`](lib/ai/runtime/native_llm_runtime.dart) |
| Model registry | [`lib/ai/models/`](lib/ai/models/) |
| Tools (Dart) | [`lib/ai/tools/`](lib/ai/tools/) — executed on tool-call events from Kotlin |
| Orchestration | [`ChatService`](lib/ai/chat/chat_service.dart) |
| UI | [`lib/features/chat/`](lib/features/chat/) |

- Default weights: **[`litert-community/gemma-4-E2B-it-litert-lm`](https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm)** → `gemma-4-E2B-it.litertlm` (~2.6 GB). Base model: [`google/gemma-4-E2B`](https://huggingface.co/google/gemma-4-E2B).
- Inference runs in **Kotlin** (not `flutter_gemma`); Dart only streams tokens via Pigeon.
- CPU/GPU: `InferenceBackendPreferences` → `LlmBackend` on load.
- Optional HF token: `ChatHfTokenPreferences` (mostly for gated URLs; Gemma 4 litert bundle is open).
- Regenerate Pigeon after API changes: `dart run pigeon --input pigeons/app_api.dart`.

### Android native

| Area | Files |
|------|--------|
| Intents / share / shortcuts | [`IntentReader.kt`](android/app/src/main/kotlin/net/exoad/linkvault/IntentReader.kt), [`shortcuts.xml`](android/app/src/main/res/xml/shortcuts.xml) |
| Flutter routing | [`IntentRouter`](lib/services/intent_router.dart), [`IntentAware`](lib/hub/hub_module.dart) on modules |
| APK install (updates) | [`InstallManager.kt`](android/app/src/main/kotlin/net/exoad/linkvault/InstallManager.kt) |
| Splash | [`SplashOrbitOverlay.kt`](android/app/src/main/kotlin/net/exoad/linkvault/SplashOrbitOverlay.kt), `notifyUiReady` via Pigeon |
| OpenCL / heap (Chat GPU) | [`AndroidManifest.xml`](android/app/src/main/AndroidManifest.xml), `minSdk` 24 in `build.gradle.kts` |

After editing [`pigeons/app_api.dart`](pigeons/app_api.dart):

```bash
dart run pigeon --input pigeons/app_api.dart
```

### Branding

Launcher and splash PNGs are generated, not hand-painted:

```bash
python3 tool/generate_branding.py   # requires: pip install Pillow, brew install librsvg
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

Source mark: [`assets/branding/head-circuit-fill.svg`](assets/branding/head-circuit-fill.svg).  
Design intent: **black canvas**, **white logo**, **subtle edge glows** (see `tool/generate_branding.py`).

## Commands

| Task | Command |
|------|---------|
| Dependencies | `flutter pub get` |
| Analyze | `flutter analyze` |
| Test | `flutter test` |
| Drift codegen | `dart run build_runner build` |
| Run (device) | `flutter run` |
| Release APK | `flutter build apk --release` |
| Launcher icons | `dart run flutter_launcher_icons` |

CI runs analyze + test on push/PR (`.github/workflows/ci.yml`). Release APK is produced on version tags — see [RELEASE.md](RELEASE.md).

**Android build note:** if Gradle fails with a Homebrew JDK image transform error, use Android Studio’s bundled JBR for `JAVA_HOME`.

## Code conventions

- **Minimize diff scope** — match existing style; no drive-by refactors.
- **Hub features** live under `lib/features/<name>/`; shared widgets under `lib/widgets/`.
- **Repositories** wrap Drift; expose streams for lists, futures for writes.
- **Wire new services** through `main.dart` and [`AppScope`](lib/app_scope.dart).
- **Comments** only for non-obvious invariants (migrations, native bridges, tool-round limits).
- **Tests** for migrations, repositories, and non-trivial pure logic; skip trivial “expect true” tests.
- **No emojis** in user-facing copy or README unless the user asks.
- **Commits** only when requested; never change git config; no force-push to `main`.

## Documentation map

| Doc | Use when |
|-----|----------|
| [README.md](README.md) | Project face, quick start |
| [AGENTS.md](AGENTS.md) | This file — agent onboarding |
| [HUB_MODULES.md](HUB_MODULES.md) | New hub app, intents |
| [DATA.md](DATA.md) | SQLite, updates, data safety |
| [RELEASE.md](RELEASE.md) | Version bump, tags, signing |
| [SECURITY.md](SECURITY.md) | Reporting vulnerabilities |

## Keeping this file current

Update **AGENTS.md** in the same change when you:

- Add/remove a hub module or change how `AppShell` routes.
- Bump database schema version or migration policy.
- Add a new top-level dependency (especially native/ML).
- Change Pigeon APIs, signing, or release workflow.
- Move branding generation or ambient/theme architecture.

When unsure, prefer linking to source files and checklists over duplicating long prose.

## Out of scope (unless user says otherwise)

- iOS/desktop targets
- Cloud sync or accounts
- Bundling LLM weights in the APK
- Marketing site or store listings
- Force-push, amending pushed commits, or skipping git hooks
