#!/usr/bin/env python3
"""Generate Android launcher icons from assets/icons/icon.png."""
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets/icons/icon.png"
MASTER_1024 = ROOT / "assets/icons/icon-1024.png"
WEB_ICON = ROOT / "assets/icons/icon.png"
RES = ROOT / "android/app/src/main/res"
BG = (27, 16, 40)  # #1b1028 — game background
WEB_SIZE = 512

DENSITIES = {
    "mdpi": (48, 108),
    "hdpi": (72, 162),
    "xhdpi": (96, 216),
    "xxhdpi": (144, 324),
    "xxxhdpi": (192, 432),
}

SAFE_ZONE_RATIO = 0.66


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


def make_foreground(master: Image.Image, size: int) -> Image.Image:
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    icon_size = int(size * SAFE_ZONE_RATIO)
    icon = master.resize((icon_size, icon_size), Image.Resampling.LANCZOS)
    offset = (size - icon_size) // 2
    canvas.paste(icon, (offset, offset), icon)
    return canvas


def make_launcher(master: Image.Image, size: int, round_icon: bool = False) -> Image.Image:
    canvas = Image.new("RGBA", (size, size), BG + (255,))
    icon_size = int(size * 0.85)
    icon = master.resize((icon_size, icon_size), Image.Resampling.LANCZOS)
    offset = (size - icon_size) // 2
    canvas.paste(icon, (offset, offset), icon)
    if not round_icon:
        return canvas
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.ellipse((0, 0, size - 1, size - 1), fill=255)
    result = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    result.paste(canvas, (0, 0), mask)
    return result


def main() -> None:
    master = load_master()
    master.save(MASTER_1024, optimize=True)
    web = master.resize((WEB_SIZE, WEB_SIZE), Image.Resampling.LANCZOS)
    web.save(WEB_ICON, optimize=True)
    print(f"Saved master icon: {MASTER_1024} ({master.size[0]}x{master.size[1]})")
    print(f"Saved web icon: {WEB_ICON} ({WEB_SIZE}x{WEB_SIZE})")

    for density, (launcher, foreground) in DENSITIES.items():
        folder = RES / f"mipmap-{density}"
        folder.mkdir(parents=True, exist_ok=True)
        make_foreground(master, foreground).save(folder / "ic_launcher_foreground.png")
        make_launcher(master, launcher, False).save(folder / "ic_launcher.png")
        make_launcher(master, launcher, True).save(folder / "ic_launcher_round.png")
        print(f"  mipmap-{density}: launcher {launcher}px, foreground {foreground}px")

    print("Android icons generated.")


if __name__ == "__main__":
    main()
