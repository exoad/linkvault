#!/usr/bin/env python3
"""Generate Linkvault launcher and splash PNGs — black canvas, white head-circuit, edge glows."""

from __future__ import annotations

import math
import random
import shutil
import subprocess
import tempfile
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
SVG_SOURCE = ROOT / "assets/branding/head-circuit-fill.svg"
OUT_DIR = ROOT / "assets/branding"

SURFACE = (0x00, 0x00, 0x00)  # #000000
WHITE = "#FFFFFF"

# Subtle AI edge glows — corners + edge midpoints only (keeps center black for white mark).
EDGE_GLOW_BLOBS: list[tuple[tuple[float, float], float, tuple[int, int, int], int]] = [
    ((0.06, 0.08), 0.30, (0x6B, 0x9F, 0xFF), 72),
    ((0.94, 0.10), 0.28, (0xFF, 0x8F, 0xAB), 68),
    ((0.08, 0.92), 0.30, (0x5E, 0xD4, 0xB8), 64),
    ((0.92, 0.90), 0.28, (0xA7, 0x8B, 0xFA), 70),
    ((0.50, 0.04), 0.26, (0x4D, 0xA8, 0xFF), 52),
    ((0.96, 0.52), 0.24, (0xFF, 0xB4, 0x7A), 48),
    ((0.04, 0.48), 0.24, (0x22, 0xD3, 0xEE), 50),
    ((0.52, 0.96), 0.26, (0xC4, 0x7A, 0xFF), 55),
]

# Extra scattered edge accents (fixed seed for reproducible builds).
_SCATTER_SEED = 0x4C1B
_SCATTER_COUNT = 6

ICON_SCALE_LAUNCHER = 0.54
ICON_SCALE_FOREGROUND = 0.62
ICON_SCALE_SPLASH = 0.44
ICON_SCALE_ANDROID12 = 0.54
ICON_SCALE_SPLASH_LOGO = 0.72


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
    blur = max(10, int(radius * 0.55))
    return layer.filter(ImageFilter.GaussianBlur(radius=blur))


def _scatter_edge_blobs(size: int) -> list[tuple[tuple[float, float], float, tuple[int, int, int], int]]:
    rng = random.Random(_SCATTER_SEED)
    hues = [
        (0x6B, 0x9F, 0xFF),
        (0xFF, 0x8F, 0xAB),
        (0x5E, 0xD4, 0xB8),
        (0xA7, 0x8B, 0xFA),
        (0x22, 0xD3, 0xEE),
        (0xFF, 0xB4, 0x7A),
    ]
    blobs: list[tuple[tuple[float, float], float, tuple[int, int, int], int]] = []
    for i in range(_SCATTER_COUNT):
        edge = rng.choice(("top", "bottom", "left", "right"))
        t = rng.uniform(0.12, 0.88)
        if edge == "top":
            center = (t, rng.uniform(0.02, 0.14))
        elif edge == "bottom":
            center = (t, rng.uniform(0.86, 0.98))
        elif edge == "left":
            center = (rng.uniform(0.02, 0.14), t)
        else:
            center = (rng.uniform(0.86, 0.98), t)
        blobs.append((center, rng.uniform(0.18, 0.26), hues[i % len(hues)], rng.randint(38, 58)))
    return blobs


def _center_protection_mask(size: int, inner_radius_frac: float = 0.38) -> Image.Image:
    """White = keep glow; black = force black (protects white logo area)."""
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    cx = cy = size / 2
    outer = size * 0.52
    inner = size * inner_radius_frac
    px = mask.load()
    for y in range(size):
        for x in range(size):
            d = math.hypot(x - cx, y - cy)
            if d <= inner:
                px[x, y] = 0
            elif d >= outer:
                px[x, y] = 255
            else:
                t = (d - inner) / (outer - inner)
                px[x, y] = int(255 * t * t)
    return mask


def paint_edge_glows(size: int, *, include_scatter: bool = True) -> Image.Image:
    base = Image.new("RGBA", (size, size), SURFACE + (255,))
    blobs = list(EDGE_GLOW_BLOBS)
    if include_scatter:
        blobs.extend(_scatter_edge_blobs(size))

    glow_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    for center, radius_frac, rgb, alpha in blobs:
        blob = _glow_blob(size, center, radius_frac, rgb, alpha)
        glow_layer = ImageChops.add(glow_layer, blob)

    protect = _center_protection_mask(size)
    black = Image.new("RGBA", (size, size), SURFACE + (255,))
    glow_layer = Image.composite(glow_layer, black, protect)
    return ImageChops.add(base, glow_layer)


def compose_branded_icon(
    size: int,
    *,
    icon_scale: float,
) -> Image.Image:
    canvas = paint_edge_glows(size)
    icon = load_colored_icon(int(size * icon_scale), WHITE)
    paste_centered(canvas, icon)
    return canvas


def make_launcher_icon(size: int = 1024) -> Image.Image:
    canvas = compose_branded_icon(size, icon_scale=ICON_SCALE_LAUNCHER)
    canvas.putalpha(rounded_rect_mask(size))
    return canvas


def make_foreground(size: int = 1024) -> Image.Image:
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    icon = load_colored_icon(int(size * ICON_SCALE_FOREGROUND), WHITE)
    paste_centered(canvas, icon)
    return canvas


def make_background(size: int = 1024) -> Image.Image:
    """Adaptive icon background: black with subtle edge chroma only."""
    return paint_edge_glows(size, include_scatter=False)


def make_splash_full(size: int) -> Image.Image:
    return compose_branded_icon(size, icon_scale=ICON_SCALE_SPLASH)


def make_android12_icon(size: int = 512) -> Image.Image:
    glow = paint_edge_glows(size, include_scatter=False)
    icon = load_colored_icon(int(size * ICON_SCALE_ANDROID12), WHITE)
    paste_centered(glow, icon)
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    inset = int(size * 0.06)
    draw.ellipse((inset, inset, size - inset, size - inset), fill=255)
    glow.putalpha(mask)
    return glow


def make_splash_logo_transparent(size: int = 512) -> Image.Image:
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    icon = load_colored_icon(int(size * ICON_SCALE_SPLASH_LOGO), WHITE)
    paste_centered(canvas, icon)
    return canvas


def copy_android_splash_logo() -> None:
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
