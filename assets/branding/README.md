# Linkvault branding

Icon: [Phosphor **vault** (fill)](https://phosphoricons.com/?q=vault) from [phosphor-icons/core](https://github.com/phosphor-icons/core) (MIT).

Source SVG: `vault-fill.svg` (downloaded from the Phosphor Icons repository).

## Regenerate PNGs

Requires `librsvg` (`brew install librsvg`):

```bash
python3 tool/generate_branding.py
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

Brand color: `#6750A4` (Material-style seed used in the app).
