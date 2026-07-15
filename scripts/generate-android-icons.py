#!/usr/bin/env python3
"""Generate Godot launcher icons from godot/assets/store/icon-1024.png."""
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
GODOT = ROOT / "godot"
SRC = GODOT / "assets/store/icon-1024.png"
MASTER_1024 = GODOT / "assets/store/icon-1024.png"
ICON_PNG = GODOT / "icon.png"
BG = (27, 16, 40)  # #1b1028 — game background
WEB_SIZE = 512


def load_master() -> Image.Image:
    if MASTER_1024.exists():
        img = Image.open(MASTER_1024).convert("RGBA")
    elif SRC.exists():
        img = Image.open(SRC).convert("RGBA")
    else:
        return create_fallback_icon()
    if img.size != (1024, 1024):
        img = img.resize((1024, 1024), Image.Resampling.LANCZOS)
    return img


def create_fallback_icon() -> Image.Image:
    size = 1024
    img = Image.new("RGBA", (size, size), BG + (255,))
    draw = ImageDraw.Draw(img)
    try:
        from PIL import ImageFont

        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 280)
    except OSError:
        font = ImageFont.load_default()
    text = "2048"
    bbox = draw.textbbox((0, 0), text, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    x = (size - tw) // 2
    y = (size - th) // 2
    for dx, dy in [(-4, 0), (4, 0), (0, -4), (0, 4), (-3, -3), (3, 3)]:
        draw.text((x + dx, y + dy), text, fill=(0, 255, 200, 120), font=font)
    draw.text((x, y), text, fill=(0, 255, 220, 255), font=font)
    return img


def main() -> None:
    master = load_master()
    master.save(MASTER_1024, optimize=True)
    icon = master.resize((WEB_SIZE, WEB_SIZE), Image.Resampling.LANCZOS)
    icon.save(ICON_PNG, optimize=True)
    print(f"Saved master icon: {MASTER_1024} ({master.size[0]}x{master.size[1]})")
    print(f"Saved Godot icon: {ICON_PNG} ({WEB_SIZE}x{WEB_SIZE})")


if __name__ == "__main__":
    main()
