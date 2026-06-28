#!/usr/bin/env python3
"""Prepare Google Play Console graphics in store/ (icon, feature graphic, phone screenshots)."""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
STORE = ROOT / "store"
ICON_SRC = ROOT / "assets/icons/icon-1024.png"
ICON_FALLBACK = ROOT / "assets/icons/icon.png"
BG = (27, 16, 40)  # #1b1028
PHONE_W, PHONE_H = 1080, 1920

SCREENSHOT_SPECS = [
    (
        "01-menu-dark.png",
        ROOT / "assets/images/dark/menu-bg-1.png",
        "Lost Number",
        "Логічна головоломка з числами",
        ["Рівні · бонуси · офлайн"],
        (255, 107, 157),
    ),
    (
        "02-menu-light.png",
        ROOT / "assets/images/light/bg-light-01.png",
        "Дві теми",
        "Темна та світла",
        ["Неон і світанок", "Зручно вдень і ввечері"],
        (120, 90, 200),
    ),
    (
        "03-levels-bonuses.png",
        ROOT / "assets/images/dark/menu-bg-3.png",
        "Рівні та бонуси",
        "Сітка 5×8",
        ["Вибух · перемішування", "Щоденні завдання"],
        (255, 180, 90),
    ),
    (
        "04-offline-calm.png",
        ROOT / "assets/images/light/bg-light-03.png",
        "Без реклами",
        "Грай у своєму темпі",
        ["Збереження на пристрої", "UA · RU · EN"],
        (90, 180, 255),
    ),
]


def load_font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    names = (
        [
            "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
            "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
        ]
        if bold
        else [
            "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
            "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf",
        ]
    )
    for path in names:
        try:
            return ImageFont.truetype(path, size)
        except OSError:
            continue
    return ImageFont.load_default()


def load_icon(size: int) -> Image.Image:
    src = ICON_SRC if ICON_SRC.exists() else ICON_FALLBACK
    if not src.exists():
        return Image.new("RGBA", (size, size), BG + (255,))
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

    font_title = load_font(64, bold=True)
    font_sub = load_font(28)

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


def cover_resize(src: Image.Image, width: int, height: int) -> Image.Image:
    """Scale and center-crop source image to fill target size."""
    sw, sh = src.size
    scale = max(width / sw, height / sh)
    nw, nh = int(sw * scale), int(sh * scale)
    resized = src.resize((nw, nh), Image.Resampling.LANCZOS)
    left = (nw - width) // 2
    top = (nh - height) // 2
    return resized.crop((left, top, left + width, top + height))


def make_phone_screenshot(
    bg_path: Path,
    title: str,
    subtitle: str,
    bullets: list[str],
    accent: tuple[int, int, int],
) -> Image.Image:
    if not bg_path.exists():
        base = Image.new("RGB", (PHONE_W, PHONE_H), BG)
    else:
        with Image.open(bg_path) as raw:
            base = cover_resize(raw.convert("RGB"), PHONE_W, PHONE_H)

    overlay = Image.new("RGBA", (PHONE_W, PHONE_H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    for y in range(PHONE_H // 2, PHONE_H):
        t = (y - PHONE_H // 2) / max(1, PHONE_H // 2 - 1)
        alpha = int(40 + 200 * t)
        draw.line([(0, y), (PHONE_W, y)], fill=(0, 0, 0, alpha))

    draw.rectangle(
        [(48, PHONE_H - 520), (PHONE_W - 48, PHONE_H - 120)],
        fill=(20, 12, 32, 180),
        outline=accent + (220,),
        width=3,
    )

    icon = load_icon(256).resize((96, 96), Image.Resampling.LANCZOS)
    overlay.paste(icon, (72, PHONE_H - 500), icon)

    font_title = load_font(52, bold=True)
    font_sub = load_font(34)
    font_bullet = load_font(28)

    text_x = 190
    draw.text((text_x, PHONE_H - 490), title, fill=(255, 245, 250, 255), font=font_title)
    draw.text((text_x, PHONE_H - 420), subtitle, fill=accent + (255,), font=font_sub)

    y = PHONE_H - 350
    for line in bullets:
        draw.text((72, y), f"• {line}", fill=(230, 220, 240, 255), font=font_bullet)
        y += 44

    return Image.alpha_composite(base.convert("RGBA"), overlay).convert("RGB")


def save_screenshots() -> None:
    phone_dir = STORE / "screenshots" / "phone"
    phone_dir.mkdir(parents=True, exist_ok=True)
    lines = [
        "# Phone screenshots (portrait 1080×1920)",
        "",
        "Play Console requires at least 2 phone screenshots.",
        "",
        "Promo composites from menu art + branding. Replace with real in-app captures before public launch.",
        "",
    ]

    for filename, src, title, subtitle, bullets, accent in SCREENSHOT_SPECS:
        dest = phone_dir / filename
        if not src.exists():
            print(f"Skip missing screenshot source: {src}")
            continue
        shot = make_phone_screenshot(src, title, subtitle, bullets, accent)
        shot.save(dest, optimize=True)
        lines.append(
            f"- `{filename}` — {PHONE_W}×{PHONE_H} — {title}: {subtitle} (promo draft)"
        )
        print(f"Saved {dest.relative_to(ROOT)} ({PHONE_W}x{PHONE_H})")

    readme = phone_dir / "README.md"
    readme.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    STORE.mkdir(parents=True, exist_ok=True)
    save_play_icon()
    save_feature_graphic()
    save_screenshots()
    print("Play Store graphics prepared in store/")


if __name__ == "__main__":
    main()
