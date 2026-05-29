# Linkvault branding

Icon: [Phosphor **head-circuit** (fill)](https://phosphoricons.com/?q=head-circuit) from [phosphor-icons/core](https://github.com/phosphor-icons/core) (MIT).

Source SVG: `head-circuit-fill.svg`.

Visual language: **black canvas** (`#000000`), **white head-circuit** mark, soft **ambient color orbs** (matches in-app lava palette). Native Android splash plays orbs orbiting from behind the logo to the front.

## Regenerate PNGs

Requires `librsvg` and Pillow:

```bash
brew install librsvg
python3 -m pip install Pillow
python3 tool/generate_branding.py
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

Outputs: launcher icons, adaptive layers, splash stills, and `android/.../drawable-nodpi/ic_head_circuit_logo.png` for the orbit splash.
