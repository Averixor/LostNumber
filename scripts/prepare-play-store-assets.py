#!/usr/bin/env python3
"""Prepare Google Play Console graphics in store/ (icon, feature graphic, draft screenshots)."""
from __future__ import annotations

import shutil
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
STORE = ROOT / "store"
ICON_SRC = ROOT / "assets/icons/icon-1024.png"
ICON_FALLBACK = ROOT / "assets/icons/icon.png"
BG = (27, 16, 40)  # #1b1028

SCREENSHOT_SOURCES = [
    (
        "01-menu-dark.png",
        ROOT / "assets/images/dark/menu-bg-1.png",
        "Draft: dark menu background (replace with in-app screenshot after QA)",
    ),
    (
        "02-menu-light.png",
        ROOT / "assets/images/light/bg-light-01.png",
        "Draft: light menu background (replace with in-app screenshot after QA)",
    ),
    (
        "03-menu-skin.png",
        ROOT / "assets/images/dark/menu-bg-3.png",
        "Draft: alternate skin (replace with settings/game capture)",
    ),
    (
        "04-menu-skin.png",
        ROOT / "assets/images/light/bg-light-03.png",
        "Draft: light skin variant (replace before public release)",
    ),
]


def load_icon(size: int) -> Image.Image:
    src = ICON_SRC if ICON_SRC.exists() else ICON_FALLBACK
    if not src.exists():
        img = Image.new("RGBA", (size, size), BG + (255,))
        return img
    img = Image.open(src).convert("RGBA")
    if img.size != (size, size):
        img = img.resize((size, size), Image.Resampling.LANCZOS)
    return img


def save_play_icon() -> None:
    out = STORE / "play-high-res-icon-512.png"
    icon = load_icon(512)
    icon.save(out, optimize=True)
    print(f"Saved {out.relative_to(ROOT)} ({out.stat().st_size // 1024} KB)")


def save_feature_graphic() -> None:
    width, height = 1024, 500
    img = Image.new("RGBA", (width, height), BG + (255,))
    draw = ImageDraw.Draw(img)

    for y in range(height):
        t = y / max(1, height - 1)
        r = int(BG[0] + (80 - BG[0]) * t)
        g = int(BG[1] + (30 - BG[1]) * t)
        b = int(BG[2] + (90 - BG[2]) * t)
        draw.line([(0, y), (width, y)], fill=(r, g, b, 255))

    icon = load_icon(1024).resize((220, 220), Image.Resampling.LANCZOS)
    img.paste(icon, (72, (height - 220) // 2), icon)

    try:
        font_title = ImageFont.truetype(
            "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 64
        )
        font_sub = ImageFont.truetype(
            "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 28
        )
    except OSError:
        font_title = ImageFont.load_default()
        font_sub = font_title

    draw.text((330, 170), "Lost Number", fill=(255, 220, 250, 255), font=font_title)
    draw.text(
        (332, 260),
        "Number puzzle · levels · bonuses",
        fill=(210, 180, 230, 255),
        font=font_sub,
    )

    out = STORE / "feature-graphic-1024x500.png"
    img.convert("RGB").save(out, optimize=True)
    print(f"Saved {out.relative_to(ROOT)} ({out.stat().st_size // 1024} KB)")


def copy_screenshots() -> None:
    phone_dir = STORE / "screenshots" / "phone"
    phone_dir.mkdir(parents=True, exist_ok=True)
    lines = ["# Phone screenshots (portrait)", "", "Play Console requires at least 2 phone screenshots.", ""]

    for filename, src, note in SCREENSHOT_SOURCES:
        dest = phone_dir / filename
        if not src.exists():
            print(f"Skip missing screenshot source: {src}")
            continue
        shutil.copy2(src, dest)
        with Image.open(dest) as shot:
            w, h = shot.size
        lines.append(f"- `{filename}` — {w}×{h} — {note}")
        print(f"Copied {dest.relative_to(ROOT)} ({w}x{h})")

    readme = phone_dir / "README.md"
    readme.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    STORE.mkdir(parents=True, exist_ok=True)
    save_play_icon()
    save_feature_graphic()
    copy_screenshots()
    print("Play Store graphics prepared in store/")


if __name__ == "__main__":
    main()
