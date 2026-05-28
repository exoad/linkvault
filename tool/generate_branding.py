#!/usr/bin/env python3
"""Generate Linkvault launcher and splash PNGs from Phosphor vault-fill SVG."""

from __future__ import annotations

import shutil
import subprocess
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
SVG_SOURCE = ROOT / "assets/branding/vault-fill.svg"
OUT_DIR = ROOT / "assets/branding"

BRAND = (0x67, 0x50, 0xA4)  # #6750A4
SPLASH_LIGHT_BG = (0xFF, 0xFF, 0xFF)
SPLASH_DARK_BG = (0x12, 0x12, 0x16)


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


def make_launcher_icon(size: int = 1024) -> Image.Image:
    canvas = Image.new("RGBA", (size, size), BRAND + (255,))
    canvas.putalpha(rounded_rect_mask(size))
    icon = load_colored_icon(int(size * 0.52), "#FFFFFF")
    paste_centered(canvas, icon)
    return canvas


def make_foreground(size: int = 1024) -> Image.Image:
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    icon = load_colored_icon(int(size * 0.62), "#FFFFFF")
    paste_centered(canvas, icon)
    return canvas


def make_background(size: int = 1024) -> Image.Image:
    return Image.new("RGBA", (size, size), BRAND + (255,))


def make_splash(size: int, *, dark: bool) -> Image.Image:
    bg = SPLASH_DARK_BG if dark else SPLASH_LIGHT_BG
    fg = "#FFFFFF" if dark else "#6750A4"
    canvas = Image.new("RGBA", (size, size), bg + (255,))
    icon = load_colored_icon(int(size * 0.45), fg)
    paste_centered(canvas, icon)
    return canvas


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    if not SVG_SOURCE.exists():
        raise SystemExit(f"Missing {SVG_SOURCE} — download vault-fill.svg from Phosphor Icons")

    make_launcher_icon().save(OUT_DIR / "app_icon.png")
    make_foreground().save(OUT_DIR / "app_icon_foreground.png")
    make_background().save(OUT_DIR / "app_icon_background.png")
    make_splash(1152, dark=False).save(OUT_DIR / "splash_icon_light.png")
    make_splash(1152, dark=True).save(OUT_DIR / "splash_icon_dark.png")

    for name, color in (
        ("splash_android12_icon.png", "#6750A4"),
        ("splash_android12_icon_dark.png", "#FFFFFF"),
    ):
        android12 = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
        icon = load_colored_icon(int(512 * 0.55), color)
        paste_centered(android12, icon)
        android12.save(OUT_DIR / name)

    print(f"Generated branding PNGs in {OUT_DIR}")


if __name__ == "__main__":
    main()
