#!/usr/bin/env python3
"""Generate Linkvault launcher and splash PNGs — black canvas, white head-circuit, ambient glow."""

from __future__ import annotations

import math
import shutil
import subprocess
import tempfile
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
SVG_SOURCE = ROOT / "assets/branding/head-circuit-fill.svg"
OUT_DIR = ROOT / "assets/branding"

SURFACE = (0x00, 0x00, 0x00)  # #000000 — matches LinkvaultMonochrome dark
WHITE = "#FFFFFF"

# Ambient lava hues (from EdgeGlowPalette presets, Aurora-forward).
GLOW_BLOBS: list[tuple[tuple[float, float], float, tuple[int, int, int], int]] = [
    ((0.26, 0.30), 0.48, (0x6B, 0x9F, 0xFF), 150),
    ((0.74, 0.72), 0.44, (0xFF, 0x8F, 0xAB), 130),
    ((0.58, 0.82), 0.40, (0x5E, 0xD4, 0xB8), 110),
    ((0.80, 0.26), 0.36, (0xA7, 0x8B, 0xFA), 95),
    ((0.42, 0.52), 0.32, (0x4D, 0xA8, 0xFF), 80),
]

# Icon occupies more of the frame than the old vault mark.
ICON_SCALE_LAUNCHER = 0.54
ICON_SCALE_FOREGROUND = 0.62
ICON_SCALE_SPLASH = 0.44
ICON_SCALE_ANDROID12 = 0.54
ICON_SCALE_SPLASH_LOGO = 0.72  # native orbit overlay (transparent)


def find_rsvg_convert() -> str:
    for candidate in (
        shutil.which("rsvg-convert"),
        "/opt/homebrew/bin/rsvg-convert",
        "/usr/local/bin/rsvg-convert",
    ):
        if candidate and Path(candidate).is_file():
            return candidate
    raise SystemExit("rsvg-convert not found. Install: brew install librsvg")


def svg_to_png(svg_text: str, size: int, out_path: Path) -> None:
    rsvg = find_rsvg_convert()
    with tempfile.NamedTemporaryFile("w", suffix=".svg", delete=False) as tmp:
        tmp.write(svg_text)
        tmp_path = Path(tmp.name)
    try:
        subprocess.run(
            [rsvg, "-w", str(size), "-h", str(size), str(tmp_path), "-o", str(out_path)],
            check=True,
            capture_output=True,
        )
    finally:
        tmp_path.unlink(missing_ok=True)


def load_colored_icon(size: int, hex_color: str) -> Image.Image:
    svg = SVG_SOURCE.read_text()
    svg = svg.replace('fill="currentColor"', f'fill="{hex_color}"')
    with tempfile.NamedTemporaryFile(suffix=".png", delete=False) as tmp:
        tmp_path = Path(tmp.name)
    try:
        svg_to_png(svg, size, tmp_path)
        return Image.open(tmp_path).convert("RGBA")
    finally:
        tmp_path.unlink(missing_ok=True)


def rounded_rect_mask(size: int, radius_ratio: float = 0.22) -> Image.Image:
    radius = int(size * radius_ratio)
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size - 1, size - 1), radius=radius, fill=255)
    return mask


def paste_centered(base: Image.Image, overlay: Image.Image) -> None:
    bx = (base.width - overlay.width) // 2
    by = (base.height - overlay.height) // 2
    base.paste(overlay, (bx, by), overlay)


def _glow_blob(
    size: int,
    center: tuple[float, float],
    radius_frac: float,
    rgb: tuple[int, int, int],
    peak_alpha: int,
) -> Image.Image:
    cx = center[0] * size
    cy = center[1] * size
    radius = radius_frac * size
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    bbox = (cx - radius, cy - radius, cx + radius, cy + radius)
    draw.ellipse(bbox, fill=rgb + (peak_alpha,))
    blur = max(8, int(radius * 0.42))
    return layer.filter(ImageFilter.GaussianBlur(radius=blur))


def paint_ambient_glow(size: int) -> Image.Image:
    base = Image.new("RGBA", (size, size), SURFACE + (255,))
    for center, radius_frac, rgb, alpha in GLOW_BLOBS:
        blob = _glow_blob(size, center, radius_frac, rgb, alpha)
        base = ImageChops.add(base, blob)
    return base


def paint_vignette(size: int, strength: float = 0.35) -> Image.Image:
    layer = Image.new("L", (size, size), 0)
    cx = cy = size / 2
    max_r = size * 0.72
    px = layer.load()
    for y in range(size):
        for x in range(size):
            d = math.hypot(x - cx, y - cy) / max_r
            px[x, y] = int(max(0, min(255, 255 * (1 - strength * d * d))))
    return layer


def compose_branded_icon(
    size: int,
    *,
    icon_scale: float,
    with_glow: bool = True,
    vignette: bool = False,
) -> Image.Image:
    canvas = paint_ambient_glow(size) if with_glow else Image.new("RGBA", (size, size), SURFACE + (255,))
    if vignette:
        vig = paint_vignette(size)
        dark = Image.new("RGBA", (size, size), (0, 0, 0, 255))
        canvas = Image.composite(canvas, dark, vig)

    icon = load_colored_icon(int(size * icon_scale), WHITE)
    paste_centered(canvas, icon)
    return canvas


def make_launcher_icon(size: int = 1024) -> Image.Image:
    canvas = compose_branded_icon(
        size, icon_scale=ICON_SCALE_LAUNCHER, with_glow=True, vignette=True,
    )
    canvas.putalpha(rounded_rect_mask(size))
    return canvas


def make_foreground(size: int = 1024) -> Image.Image:
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    icon = load_colored_icon(int(size * ICON_SCALE_FOREGROUND), WHITE)
    paste_centered(canvas, icon)
    return canvas


def make_background(size: int = 1024) -> Image.Image:
    canvas = paint_ambient_glow(size)
    vig = paint_vignette(size)
    dark = Image.new("RGBA", (size, size), SURFACE + (255,))
    return Image.composite(canvas, dark, vig)


def make_splash_full(size: int) -> Image.Image:
    return compose_branded_icon(size, icon_scale=ICON_SCALE_SPLASH, with_glow=True, vignette=False)


def make_android12_icon(size: int = 512) -> Image.Image:
    glow = paint_ambient_glow(size)
    icon = load_colored_icon(int(size * ICON_SCALE_ANDROID12), WHITE)
    paste_centered(glow, icon)
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    inset = int(size * 0.06)
    draw.ellipse((inset, inset, size - inset, size - inset), fill=255)
    glow.putalpha(mask)
    return glow


def make_splash_logo_transparent(size: int = 512) -> Image.Image:
    """White head-circuit on transparent — used by native orbit splash overlay."""
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    icon = load_colored_icon(int(size * ICON_SCALE_SPLASH_LOGO), WHITE)
    paste_centered(canvas, icon)
    return canvas


def copy_android_splash_logo() -> None:
    """Push logo into Android res for Kotlin splash overlay."""
    src = OUT_DIR / "splash_logo.png"
    if not src.exists():
        return
    dest_dir = ROOT / "android/app/src/main/res/drawable-nodpi"
    dest_dir.mkdir(parents=True, exist_ok=True)
    shutil.copy(src, dest_dir / "ic_head_circuit_logo.png")


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    if not SVG_SOURCE.exists():
        raise SystemExit(
            f"Missing {SVG_SOURCE} — fetch from phosphor-icons/core assets/fill/head-circuit-fill.svg"
        )

    make_launcher_icon().save(OUT_DIR / "app_icon.png")
    make_foreground().save(OUT_DIR / "app_icon_foreground.png")
    make_background().save(OUT_DIR / "app_icon_background.png")
    make_splash_full(1152).save(OUT_DIR / "splash_icon_dark.png")
    make_android12_icon(512).save(OUT_DIR / "splash_android12_icon_dark.png")
    make_splash_logo_transparent(512).save(OUT_DIR / "splash_logo.png")

    shutil.copy(OUT_DIR / "splash_icon_dark.png", OUT_DIR / "splash_icon_light.png")
    shutil.copy(
        OUT_DIR / "splash_android12_icon_dark.png",
        OUT_DIR / "splash_android12_icon.png",
    )

    copy_android_splash_logo()
    print(f"Generated branding PNGs in {OUT_DIR}")


if __name__ == "__main__":
    main()
